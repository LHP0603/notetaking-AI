import os
import json
from typing import Dict, Any
from dotenv import load_dotenv
from google import genai
from google.genai import types

load_dotenv()

GEMINI_API_KEY = os.getenv('GEMINI_API_KEY')

if not GEMINI_API_KEY:
    raise ValueError('GEMINI_API_KEY is not set in .env file')

client = genai.Client(api_key=GEMINI_API_KEY)

def generate_summary_gemini(transcript_text: str, summary_style: str = "MEETING") -> Dict[str, Any]:
    """
    Generates a summary from transcript text using Gemini.
    
    Args:
        transcript_text: The cleaned transcript text
        summary_style: The style of summary to generate (default: MEETING)
        
    Returns:
        Dictionary containing the summary structure (overview, key_points, action_items)
    """
    
    prompt = f"""
    You are an expert AI meeting assistant. Your task is to summarize the following meeting transcript.
    Summary Style: {summary_style}
    
    Transcript:
    {transcript_text}
    """
    
    try:
        response = client.models.generate_content(
            model="gemini-2.5-flash-lite",
            contents=[prompt],
            config=types.GenerateContentConfig(
                response_mime_type='application/json',
                response_schema={
                    "type": "object",
                    "properties": {
                        "overview": {"type": "string", "description": "A concise paragraph summarizing the main purpose and outcome of the meeting."},
                        "key_points": {
                            "type": "array",
                            "items": {"type": "string", "description": "Key point discussed"}
                        },
                        "action_items": {
                            "type": "array",
                            "items": {"type": "string", "description": "Action item with owner if applicable"}
                        }
                    },
                    "required": ["overview", "key_points", "action_items"]
                },
                thinking_config=types.ThinkingConfig(thinking_budget=0)
            )
        )
        
        return json.loads(response.text)
    except Exception as e:
        print(f"Error generating summary: {e}")
        # Return a fallback structure in case of error
        return {
            "overview": "Error generating summary.",
            "key_points": [],
            "action_items": []
        }
