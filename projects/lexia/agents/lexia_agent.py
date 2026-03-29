# projects/lexia/agents/lexia_agent.py
import os, json
from pathlib import Path
import openai

BASE_DIR = Path(__file__).resolve().parents[1]
PROMPT_TXT = (BASE_DIR / "prompts" / "core_prompt.txt").read_text()
openai.api_key = os.getenv("OPENAI_API_KEY", "")

class LexiaAgent:
    def __init__(self, model=None, temperature=0.6):
        self.model = model or os.getenv('OPENAI_MODEL','gpt-4o-mini')
        self.temperature = temperature

    def build_prompt(self, level, profession, user_utterance):
        p = PROMPT_TXT
        p = p.replace("{level}", level or "B1")
        p = p.replace("{profession}", profession or "General")
        p = p.replace("{user_utterance}", user_utterance or "")
        return p

    def call_llm(self, system_prompt, user_message):
        messages = [
            {"role":"system", "content": system_prompt},
            {"role":"user", "content": user_message}
        ]
        resp = openai.ChatCompletion.create(
            model=self.model,
            messages=messages,
            temperature=self.temperature,
            max_tokens=400
        )
        txt = resp.choices[0].message.content.strip()
        try:
            return json.loads(txt)
        except Exception:
            # Try to extract JSON
            import re
            m = re.search(r"\{.*\}", txt, re.S)
            if m:
                try:
                    return json.loads(m.group(0))
                except:
                    pass
            return {"text": txt, "new_words": [], "corrections": [], "action": None}

    def handle_turn(self, user_id, level, profession, user_utterance):
        system_prompt = self.build_prompt(level, profession, user_utterance)
        user_message = f"Usuario: {user_utterance}\nResponde en JSON según las reglas."
        return self.call_llm(system_prompt, user_message)
