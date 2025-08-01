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
        "This is a test message that will be streamed character by character.",
        "Welcome to our streaming API test",
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
        "The quick brown fox jumps over the lazy dog.",
        "In software development, the only constant is change.",
        "Clean code is not about perfection. It is about honesty.",
        "The best error message is the one that never shows up.",
    ]
    
    # Select 3 random texts
    selected_texts = random.sample(sample_texts, 3)
    
    # Generate response data
    response_data = {
        "id": str(uuid.uuid4()),
        "datetime": datetime.now().isoformat(),
        "texts": selected_texts
    }
    
    async def generate_stream():
        # Send the initial JSON structure
        initial_data = {
            "id": response_data["id"],
            "datetime": response_data["datetime"],
            "texts": ["", "", ""]
        }
        yield json.dumps(initial_data, ensure_ascii=False) + "\n"
        
        # Initialize accumulated texts array
        accumulated_texts = ["", "", ""]
        
        # Stream each text character by character in chunks
        for text_index, text in enumerate(response_data["texts"]):
            position = 0
            
            while position < len(text):
                # Random chunk size between 4 and 8 characters
                chunk_size = random.randint(4, 8)
                chunk_size = min(chunk_size, len(text) - position)
                
                chunk = text[position:position + chunk_size]
                position += chunk_size
                accumulated_texts[text_index] += chunk
                
                # Send a complete JSON object with updated texts
                update_data = {
                    "id": response_data["id"],
                    "datetime": response_data["datetime"],
                    "texts": accumulated_texts
                }
                yield json.dumps(update_data, ensure_ascii=False) + "\n"
                
                # Wait 0.5 seconds before next chunk
                await asyncio.sleep(0.5)
    
    return StreamingResponse(
        generate_stream(),
        media_type="text/plain"
    )