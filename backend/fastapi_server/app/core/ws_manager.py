import json
from fastapi import WebSocket
from collections import defaultdict


class ConnectionManager:
    def __init__(self):
        # user_id -> list[WebSocket]
        self._user_sockets: dict[str, list[WebSocket]] = defaultdict(list)
        # room -> list[WebSocket]
        self._rooms: dict[str, list[WebSocket]] = defaultdict(list)
        # websocket -> user_id
        self._socket_user: dict[WebSocket, str] = {}

    async def connect(self, ws: WebSocket, user_id: str):
        await ws.accept()
        self._user_sockets[user_id].append(ws)
        self._socket_user[ws] = user_id

    def disconnect(self, ws: WebSocket):
        user_id = self._socket_user.pop(ws, None)
        if user_id:
            sockets = self._user_sockets.get(user_id, [])
            if ws in sockets:
                sockets.remove(ws)
        # remove from all rooms
        for room_sockets in self._rooms.values():
            if ws in room_sockets:
                room_sockets.remove(ws)

    def join_room(self, ws: WebSocket, room: str):
        if ws not in self._rooms[room]:
            self._rooms[room].append(ws)

    def leave_room(self, ws: WebSocket, room: str):
        sockets = self._rooms.get(room, [])
        if ws in sockets:
            sockets.remove(ws)

    async def emit_to_room(self, room: str, event: str, data: dict):
        payload = json.dumps({"event": event, "data": data})
        dead = []
        for ws in self._rooms.get(room, []):
            try:
                await ws.send_text(payload)
            except Exception:
                dead.append(ws)
        for ws in dead:
            self.disconnect(ws)

    async def emit_to_user(self, user_id: str, event: str, data: dict):
        payload = json.dumps({"event": event, "data": data})
        dead = []
        for ws in self._user_sockets.get(user_id, []):
            try:
                await ws.send_text(payload)
            except Exception:
                dead.append(ws)
        for ws in dead:
            self.disconnect(ws)

    async def broadcast_to_room(self, room: str, event: str, data: dict):
        await self.emit_to_room(room, event, data)

    def get_user_id(self, ws: WebSocket) -> str | None:
        return self._socket_user.get(ws)

    @property
    def drivers_online_room(self) -> str:
        return "drivers_online"


ws_manager = ConnectionManager()
