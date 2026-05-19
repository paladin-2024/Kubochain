import json
import uuid
from datetime import datetime, timezone
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update
from ..database import get_db, AsyncSessionLocal
from ..models.user import User
from ..models.driver import Driver
from ..models.ride import Ride
from ..models.message import Message
from ..core.security import decode_access_token
from ..core.ws_manager import ws_manager
from ..services.notifications import send_push

router = APIRouter(tags=["websocket"])


async def _authenticate_ws(token: str) -> User | None:
    try:
        payload = decode_access_token(token)
        user_id = payload.get("sub")
        if not user_id:
            return None
        async with AsyncSessionLocal() as db:
            return await db.get(User, uuid.UUID(user_id))
    except Exception:
        return None


@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    # Authenticate via query param or first message
    token = websocket.query_params.get("token")
    if not token:
        await websocket.accept()
        try:
            raw = await websocket.receive_text()
            data = json.loads(raw)
            token = data.get("token")
        except Exception:
            await websocket.close(code=4001)
            return

    user = await _authenticate_ws(token)
    if not user:
        await websocket.close(code=4001)
        return

    await ws_manager.connect(websocket, str(user.id))

    try:
        while True:
            raw = await websocket.receive_text()
            try:
                msg = json.loads(raw)
            except json.JSONDecodeError:
                continue

            event = msg.get("event")
            data = msg.get("data", {})

            if event == "driver:setOnline":
                is_online = data.get("isOnline", False)
                async with AsyncSessionLocal() as db:
                    driver = (await db.execute(select(Driver).where(Driver.user_id == user.id))).scalar_one_or_none()
                    if driver:
                        driver.is_online = is_online
                        await db.commit()
                if is_online:
                    ws_manager.join_room(websocket, ws_manager.drivers_online_room)
                else:
                    ws_manager.leave_room(websocket, ws_manager.drivers_online_room)

            elif event == "driver:updateLocation":
                lat = data.get("lat")
                lng = data.get("lng")
                if lat is None or lng is None:
                    continue
                async with AsyncSessionLocal() as db:
                    driver = (await db.execute(select(Driver).where(Driver.user_id == user.id))).scalar_one_or_none()
                    if driver:
                        driver.lat = lat
                        driver.lng = lng
                        await db.commit()
                        active_ride = (await db.execute(
                            select(Ride).where(
                                Ride.driver_id == driver.id,
                                Ride.status.in_(["accepted", "arriving", "in_progress"]),
                            ).limit(1)
                        )).scalar_one_or_none()
                        if active_ride:
                            await ws_manager.emit_to_room(
                                f"ride_{active_ride.id}",
                                "ride:driverLocation",
                                {"lat": lat, "lng": lng, "rideId": str(active_ride.id)},
                            )

            elif event == "ride:join":
                ride_id = data.get("rideId")
                if ride_id:
                    ws_manager.join_room(websocket, f"ride_{ride_id}")

            elif event == "ride:leave":
                ride_id = data.get("rideId")
                if ride_id:
                    ws_manager.leave_room(websocket, f"ride_{ride_id}")

            elif event == "ride:arrived":
                ride_id = data.get("rideId")
                if ride_id:
                    async with AsyncSessionLocal() as db:
                        ride = await db.get(Ride, uuid.UUID(ride_id))
                        if ride:
                            ride.status = "arriving"
                            ride.arrived_at = datetime.now(timezone.utc)
                            await db.commit()
                    await ws_manager.emit_to_room(f"ride_{ride_id}", "ride:driverArrived", {"rideId": ride_id})

            elif event == "chat:send":
                ride_id = data.get("rideId")
                receiver_id = data.get("receiverId")
                content = (data.get("content") or "").strip()
                if not all([ride_id, receiver_id, content]):
                    continue

                async with AsyncSessionLocal() as db:
                    msg_obj = Message(
                        ride_id=uuid.UUID(ride_id),
                        sender_id=user.id,
                        receiver_id=uuid.UUID(receiver_id),
                        content=content,
                    )
                    db.add(msg_obj)
                    await db.commit()
                    await db.refresh(msg_obj)

                    payload = {
                        "id": str(msg_obj.id),
                        "rideId": ride_id,
                        "senderId": str(user.id),
                        "receiverId": receiver_id,
                        "content": content,
                        "isRead": False,
                        "senderFirstName": user.first_name,
                        "senderLastName": user.last_name,
                        "senderProfileImage": user.profile_image,
                        "createdAt": msg_obj.created_at.isoformat(),
                    }
                    await ws_manager.emit_to_room(f"ride_{ride_id}", "chat:message", {"message": payload})

                    receiver = await db.get(User, uuid.UUID(receiver_id))
                    if receiver and receiver.fcm_token:
                        sender_name = f"{user.first_name} {user.last_name}".strip() or "Someone"
                        await send_push(
                            token=receiver.fcm_token,
                            title=sender_name,
                            body=content[:120],
                            data={"type": "chat_message", "rideId": ride_id, "senderId": str(user.id)},
                        )

            elif event == "chat:read":
                ride_id = data.get("rideId")
                if ride_id:
                    async with AsyncSessionLocal() as db:
                        await db.execute(
                            update(Message)
                            .where(Message.ride_id == uuid.UUID(ride_id), Message.receiver_id == user.id)
                            .values(is_read=True)
                        )
                        await db.commit()
                    await ws_manager.emit_to_room(f"ride_{ride_id}", "chat:read", {"rideId": ride_id, "userId": str(user.id)})

    except WebSocketDisconnect:
        pass
    finally:
        ws_manager.disconnect(websocket)
