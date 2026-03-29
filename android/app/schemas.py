# app/schemas.py
from pydantic import BaseModel
from typing import Optional, List

class UserCreate(BaseModel):
    name: str
    email: str
    password: str
    country: Optional[str] = None
    profession: Optional[str] = None

class UserAuth(BaseModel):
    email: str
    password: str

class UserOut(BaseModel):
    id: int
    name: str
    email: str
    profession: Optional[str] = None

    class Config:
        orm_mode = True

class ChatRequest(BaseModel):
    user_id: int
    profession: Optional[str] = None
    level: Optional[str] = None
    message: str
