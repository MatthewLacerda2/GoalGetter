from backend.services.gemini.prompt import chat_system_prompt
from backend.services.gemini.schema import StudentContextToChat
from backend.utils.gemini.gemini_configs import get_client, get_gemini_config
from backend.services.gemini.schema import ChatMessageWithGemini, GeminiChatResponse

def gemini_messages_generator(
    messages: list[ChatMessageWithGemini], contexts: list[StudentContextToChat], objective_name: str, objective_description: str, goal_name: str
) -> GeminiChatResponse:
    
    client = get_client()
    model = "gemini-2.5-flash"
    config = get_gemini_config(GeminiChatResponse.model_json_schema())
    full_prompt = chat_system_prompt(objective_name, objective_description, goal_name, contexts)    
    messages.append(ChatMessageWithGemini(message=full_prompt, role="system", time="10:00:29"))
    
    # Convert ChatMessageWithGemini objects to the format Gemini expects
    gemini_messages = []
    for msg in messages:
        gemini_messages.append({
            "role": "user" if msg.role == "user" else "model",  # Gemini uses "model" instead of "assistant"
            "parts": [{"text": msg.message}]
        })
    
    print("\n" + str(len(gemini_messages)) + " messages\n")

    response = client.models.generate_content(
        model=model, contents=gemini_messages, config=config
    )
    
    json_response = response.text
    
    return GeminiChatResponse.model_validate_json(json_response)

if __name__ == "__main__":
    
    messages = [
        ChatMessageWithGemini(message="Write a checklist for turning on the Cessna 150", role="user", time="10:00:00"),
        ChatMessageWithGemini(message="- RPM: 100%, Fuel Flow: 100%\n- Battery: ON\n- Alternator: ON\n- Ignition: ON\n- Press Turn On", role="assistant", time="10:00:10"),
        ChatMessageWithGemini(message="What are you doing?", role="user", time="10:00:13"),
        ChatMessageWithGemini(message="Im tryna remember how to turn it on", role="user", time="10:00:23"),
        ChatMessageWithGemini(message="I managed it before but forgot", role="assistant", time="10:00:28"),
    ]
    
    print(gemini_messages_generator(
        messages=messages,
        contexts=[
            StudentContextToChat(
                state="The student has started about a two weeks ago",
            ),
            StudentContextToChat(
                metacognition="The student is an enthusiastic learner",
            ),
            StudentContextToChat(
                state="The student has a background in similar subjects",
                metacognition="The student often rushes overconfidently without being a strong foundation"
            ),
        ],
        objective_name="Learn how to start a plane",
        objective_description="Knowledge of how to turn on and start a plane by heart",
        goal_name="Fly 1000miles+ flight"
    ))