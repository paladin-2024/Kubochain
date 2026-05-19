from pydantic import BaseModel
from typing import Optional
from datetime import datetime
import uuid


class SendMessageIn(BaseModel):
    receiver_id: uuid.UUID
    content: str


class MessageOut(BaseModel):
    id: uuid.UUID
    ride_id: Optional[uuid.UUID] = None
    sender_id: Optional[uuid.UUID] = None
    receiver_id: Optional[uuid.UUID] = None
    content: str
    is_read: bool
    sender_first_name: Optional[str] = None
    sender_last_name: Optional[str] = None
    sender_profile_image: Optional[str] = None
    created_at: datetime


class ConversationOut(BaseModel):
    ride_id: uuid.UUID
    other_user_id: Optional[uuid.UUID] = None
    other_user_name: Optional[str] = None
    other_user_image: Optional[str] = None
    last_message: Optional[str] = None
    unread_count: int
    last_message_at: Optional[datetime] = None
