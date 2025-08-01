from fastapi import APIRouter
from fastapi.responses import StreamingResponse
from backend.utils.gemini import get_gemini_follow_up_questions, get_gemini_roadmap_creation
import json
import uuid
import asyncio
from datetime import datetime
import random

router = APIRouter()

@router.post(
    "/",
    status_code=200,
    description="Whatever tests you want to do")
async def test():
    # Sample texts for streaming
    sample_texts = [
        "Hello world! This is a test message that will be streamed character by character.",
        "Welcome to our streaming API test. This text will be sent in chunks.",
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
        "The quick brown fox jumps over the lazy dog. This pangram contains every letter of the alphabet.",
        "Programming is the art of telling another human being what one wants the computer to do.",
        "In software development, the only constant is change. Embrace it and adapt quickly.",
        "Clean code is not about perfection. It is about honesty. You leave when you know you are far from being done.",
        "The best error message is the one that never shows up.",
    ]
    
    # Select a random text
    selected_text = random.choice(sample_texts)
    
    # Generate response data
    response_data = {
        "id": str(uuid.uuid4()),
        "datetime": datetime.now().isoformat(),
        "text": selected_text
    }
    
    async def generate_stream():
        # Send the initial JSON structure
        initial_data = {
            "id": response_data["id"],
            "datetime": response_data["datetime"],
            "text": ""
        }
        yield json.dumps(initial_data, ensure_ascii=False) + "\n"
        
        # Stream the text character by character in chunks
        text = response_data["text"]
        position = 0
        accumulated_text = ""
        
        while position < len(text):
            # Random chunk size between 4 and 8 characters
            chunk_size = random.randint(4, 8)
            chunk_size = min(chunk_size, len(text) - position)
            
            chunk = text[position:position + chunk_size]
            position += chunk_size
            accumulated_text += chunk
            
            # Send a complete JSON object with updated text
            update_data = {
                "id": response_data["id"],
                "datetime": response_data["datetime"],
                "text": accumulated_text
            }
            yield json.dumps(update_data, ensure_ascii=False) + "\n"
            
            # Wait 0.5 seconds before next chunk
            await asyncio.sleep(0.5)
    
    return StreamingResponse(
        generate_stream(),
        media_type="text/plain"
    )