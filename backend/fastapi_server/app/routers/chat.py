import uuid
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, text
from ..database import get_db
from ..models.user import User
from ..models.message import Message
from ..schemas.chat import SendMessageIn, MessageOut, ConversationOut
from ..core.dependencies import get_current_user
from ..services.notifications import send_push

router = APIRouter(prefix="/chat", tags=["chat"])


def _message_to_out(msg: Message, sender: User | None) -> MessageOut:
    return MessageOut(
        id=msg.id,
        ride_id=msg.ride_id,
        sender_id=msg.sender_id,
        receiver_id=msg.receiver_id,
        content=msg.content,
        is_read=msg.is_read,
        sender_first_name=sender.first_name if sender else None,
        sender_last_name=sender.last_name if sender else None,
        sender_profile_image=sender.profile_image if sender else None,
        created_at=msg.created_at,
    )


@router.get("/conversations")
async def get_conversations(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(text("""
        SELECT DISTINCT ON (m.ride_id)
            m.ride_id,
            CASE WHEN m.sender_id = :uid THEN m.receiver_id ELSE m.sender_id END AS other_id,
            m.content AS last_message,
            m.created_at AS last_message_at,
            (SELECT COUNT(*) FROM messages WHERE ride_id = m.ride_id
             AND receiver_id = :uid AND is_read = false) AS unread_count
        FROM messages m
        WHERE m.sender_id = :uid OR m.receiver_id = :uid
        ORDER BY m.ride_id, m.created_at DESC
    """), {"uid": str(current_user.id)})

    rows = result.fetchall()
    conversations = []
    for r in rows:
        other_id = r[1]
        other_user = await db.get(User, other_id) if other_id else None
        conversations.append(ConversationOut(
            ride_id=r[0],
            other_user_id=other_id,
            other_user_name=f"{other_user.first_name} {other_user.last_name}".strip() if other_user else None,
            other_user_image=other_user.profile_image if other_user else None,
            last_message=r[2],
            unread_count=int(r[4] or 0),
            last_message_at=r[3],
        ))
    return {"conversations": conversations}


@router.get("/{ride_id}")
async def get_messages(
    ride_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Message)
        .where(Message.ride_id == ride_id)
        .order_by(Message.created_at.asc())
    )
    messages = result.scalars().all()

    out = []
    for msg in messages:
        sender = await db.get(User, msg.sender_id) if msg.sender_id else None
        out.append(_message_to_out(msg, sender))

    return {"messages": out}


@router.post("/{ride_id}")
async def send_message(
    ride_id: uuid.UUID,
    body: SendMessageIn,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    msg = Message(
        ride_id=ride_id,
        sender_id=current_user.id,
        receiver_id=body.receiver_id,
        content=body.content.strip(),
    )
    db.add(msg)
    await db.commit()
    await db.refresh(msg)

    msg_out = _message_to_out(msg, current_user)

    # Real-time delivery via WebSocket
    from ..core.ws_manager import ws_manager
    await ws_manager.emit_to_room(f"ride_{ride_id}", "chat:message", {"message": msg_out.model_dump(mode="json")})

    # FCM push to receiver
    receiver = await db.get(User, body.receiver_id)
    if receiver and receiver.fcm_token:
        sender_name = f"{current_user.first_name} {current_user.last_name}".strip() or "Someone"
        await send_push(
            token=receiver.fcm_token,
            title=f"{sender_name}",
            body=body.content.strip()[:120] or "Sent you a message",
            data={"type": "chat_message", "rideId": str(ride_id), "senderId": str(current_user.id)},
        )

    return {"message": msg_out}
