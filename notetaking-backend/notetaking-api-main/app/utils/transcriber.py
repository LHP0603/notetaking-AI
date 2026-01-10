import os
from dotenv import load_dotenv
from google import genai
from google.genai import types
 
load_dotenv()

GEMINI_API_KEY = os.getenv('GEMINI_API_KEY')

if not GEMINI_API_KEY:
    raise ValueError('GEMINI_API_KEY is not set in .env file')

client = genai.Client(api_key=GEMINI_API_KEY)

def transcribe(audio_bytes: bytes, file_extension: str):
    prompt = '''
    Transcribe the provided audio file verbatim, identifying different speakers based on voice changes (label them as SPEAKER_01, SPEAKER_02, etc., starting from SPEAKER_01 for the first voice). For each spoken segment, provide:
    - The start time and end time of the segment in seconds (float).
    - The exact spoken content without any repetition, filler words (unless essential), or summarization.

    Output ONLY a valid JSON array of objects, nothing else. Do not include any introduction, explanation, or additional text. Structure each object as:
    {
        "speaker_label": "SPEAKER_01", (e.g., "SPEAKER_01")
        "start_time": 0.0, (e.g., 0.0)
        "end_time": 10.5, (e.g., 10.5)
        "content": "The exact transcribed text for that segment."
    }

    If the audio has only one speaker, use SPEAKER_01 throughout. Ensure the transcript is complete but concise, covering the entire audio without duplicates.
    '''

    # Tạo audio part từ bytes
    mime_type = f"audio/{file_extension}"
    audio_part = types.Part.from_bytes(data=audio_bytes, mime_type=mime_type)

    response = client.models.generate_content(
        model="gemini-2.5-flash-lite",
        contents=[
            prompt,
            audio_part
        ],
        config=types.GenerateContentConfig(
            temperature=0,
            top_p=0,
            response_mime_type='application/json',
            response_schema={
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "speaker_label": {"type": "string", "description": "Speaker label, e.g., SPEAKER_01"},
                        "start_time": {"type": "number", "description": "Start time of the segment in seconds"},
                        "end_time": {"type": "number", "description": "End time of the segment in seconds"},
                        "content": {"type": "string", "description": "Verbatim transcribed text for the segment"}
                    },
                    "required": ["speaker_label", "start_time", "end_time", "content"]
                }
            },
            thinking_config=types.ThinkingConfig(thinking_budget=0)
        )
    )

    return response.text
