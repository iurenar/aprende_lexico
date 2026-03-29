# app/models.py
from sqlalchemy import Column, Integer, String, JSON, TIMESTAMP
from app.db import Base
from sqlalchemy.sql import func

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    email = Column(String, unique=True, index=True)
    password = Column(String)
    profession = Column(String, nullable=True)
    country = Column(String, nullable=True)
    level = Column(String, default="A1")

class LexCard(Base):
    __tablename__ = "lex_cards"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=True)
    word = Column(String)
    definition = Column(String)
    examples = Column(JSON)
    metadata = Column(JSON)
    created_at = Column(TIMESTAMP, server_default=func.now())
