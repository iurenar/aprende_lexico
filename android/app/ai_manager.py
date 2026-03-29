# app/ai_manager.py
import os, json
import openai
from typing import Dict, Any

openai.api_key = os.getenv("OPENAI_API_KEY", "")

CORE_PROMPT = '''
Eres LEXIA, un asistente de aprendizaje de español cuyo objetivo es ampliar el léxico del usuario.
Devuelve JSON con campos: text, new_words (lista), corrections (lista), action (opcional).
Contexto: Profesión: {profession}, Nivel: {level}
'''

async def handle_user_message(user_id: int, profession: str, message: str, level: str) -> Dict[str, Any]:
    system_prompt = CORE_PROMPT.format(profession=(profession or "General"), level=(level or "B1"))
    user_prompt = f"Usuario dice: {message}\nResponde en JSON."
    try:
        resp = openai.ChatCompletion.create(
            model=os.getenv('OPENAI_MODEL','gpt-4o-mini'),
            messages=[
                {"role":"system", "content": system_prompt},
                {"role":"user", "content": user_prompt}
            ],
            temperature=0.6,
            max_tokens=400
        )
        text = resp.choices[0].message.content.strip()
        try:
            parsed = json.loads(text)
        except Exception:
            # Fallback to return text-only structure
            parsed = {"text": text, "new_words": [], "corrections": [], "action": None}
        return parsed
    except Exception as e:
        return {"text": f"Error interno: {str(e)}", "new_words": [], "corrections": [], "action": None}
{
  "reply_text": "Muy bien, aquí tienes una alternativa: ...",
  "corrections": [
    {
      "original": "hacer",
      "suggestion": "realizar",
      "explanation": "En contextos formales 'realizar' es más preciso."
    }
  ],
  "recommendations": [
    "Intenta usar conectores como 'además' o 'por consiguiente' para enlazar ideas.",
    "Varía los sinónimos de 'bueno' por 'beneficioso', 'positivo', 'favorable'."
  ],
  "new_words": [
    {"word":"jurisprudencia","definition":"...","examples":["..."]}
  ]
}
