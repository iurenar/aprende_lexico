# app/config.py - VERSIÓN DEFINITIVA Y FUNCIONAL
import os
from dotenv import load_dotenv

# Cargar variables de entorno
load_dotenv()

# Configuración simple y directa
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./lexia.db")
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-change-in-production")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
ENVIRONMENT = os.getenv("ENVIRONMENT", "development")
DEBUG = os.getenv("DEBUG", "True").lower() == "true"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7

ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://localhost:8080",
    "http://localhost:53589",
    "http://localhost",
]

MAX_AUDIO_SIZE = 10 * 1024 * 1024
ALLOWED_AUDIO_TYPES = ["audio/wav", "audio/mpeg", "audio/ogg"]

# Para importar desde otros archivos
class Settings:
    pass

# Asignar todas las variables a la clase
settings = Settings()
settings.DATABASE_URL = DATABASE_URL
settings.SECRET_KEY = SECRET_KEY
settings.OPENAI_API_KEY = OPENAI_API_KEY
settings.ENVIRONMENT = ENVIRONMENT
settings.DEBUG = DEBUG
settings.ALGORITHM = ALGORITHM
settings.ACCESS_TOKEN_EXPIRE_MINUTES = ACCESS_TOKEN_EXPIRE_MINUTES
settings.ALLOWED_ORIGINS = ALLOWED_ORIGINS
settings.MAX_AUDIO_SIZE = MAX_AUDIO_SIZE
settings.ALLOWED_AUDIO_TYPES = ALLOWED_AUDIO_TYPES