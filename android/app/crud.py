# app/crud.py
from app.db import SessionLocal
from app.models import User
from sqlalchemy.orm import Session

def create_user(user_in):
    db = SessionLocal()
    user = User(name=user_in.name, email=user_in.email, password=user_in.password, profession=user_in.profession, country=user_in.country)
    db.add(user)
    db.commit()
    db.refresh(user)
    db.close()
    return user

def authenticate_user(email, password):
    db = SessionLocal()
    user = db.query(User).filter(User.email == email, User.password == password).first()
    db.close()
    return user

def get_user(user_id):
    db = SessionLocal()
    user = db.query(User).filter(User.id == user_id).first()
    db.close()
    return user
