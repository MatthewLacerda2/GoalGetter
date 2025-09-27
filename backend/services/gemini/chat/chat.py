from google.genai.types import GenerateContentResponse
from backend.utils.gemini.gemini_configs import get_client, get_gemini_config
from backend.services.gemini.chat.prompt import chat_system_prompt
from backend.services.gemini.chat.schema import StudentContextToChat, GeminiChatMessage, GeminiChatResponse

def gemini_messages_generator(
    messages: list[GeminiChatMessage], contexts: list[StudentContextToChat], objective_name: str, objective_description: str, goal_name: str
) -> GeminiChatResponse:
    
    client = get_client()
    model = "gemini-2.5-flash"
    config = get_gemini_config(GeminiChatResponse.model_json_schema())
    config.temperature = 1
    full_prompt = chat_system_prompt(objective_name, objective_description, goal_name, contexts)    
    messages.append(GeminiChatMessage(message=full_prompt, role="model", time="10:00:29"))
    
    gemini_messages = []
    for msg in messages:
        gemini_messages.append({
            "role": msg.role,
            "parts": [{"text": msg.message}]
        })

    response: GenerateContentResponse = client.models.generate_content(
        model=model, contents=gemini_messages, config=config
    )
    
    #print("Total tokens:", response.usage_metadata.total_token_count)
    #print("Total tokens:", response.usage_metadata.prompt_token_count)
    #print("Total tokens:", response.usage_metadata.candidates_token_count)
    
    json_response = response.text
    
    return GeminiChatResponse.model_validate_json(json_response)

if __name__ == "__main__":
    
    messages = [
        GeminiChatMessage(message="What are you doing?", role="model", time="10:00:13"),
        GeminiChatMessage(message="Hey is ma checklist right? Its for turning on the Cessna 150", role="user", time="10:00:00"),
        GeminiChatMessage(message="Im tryna remember how to turn it on", role="user", time="10:00:23"),
        GeminiChatMessage(message="- RPM: 100%, Fuel Flow: 100%\n- Battery: ON\n- Alternator: ON\n- Ignition: ON\n- Press Turn On", role="user", time="10:00:10"),
        GeminiChatMessage(message="No, this checklist is incorrect.", role="model", time="10:00:00"),
        GeminiChatMessage(message="RPM and Fuel Flow are not settings you adjust to 'turn on' the plane. Those are readouts or power settings used after the engine is running.", role="model", time="10:00:00"),
        GeminiChatMessage(message="You're missing critical steps like setting the parking brake, fuel selector, mixture, and throttle properly. You also need to prime the engine.", role="model", time="10:00:00"),
        GeminiChatMessage(message="'Press Turn On' is too vague. You need to engage the starter.", role="model", time="10:00:00"),
        GeminiChatMessage(message="You need to consult the Pilot's Operating Handbook (POH) for the Cessna 150. That will give you the precise, correct, and safe startup procedure. Guessing leads to mistakes.", role="model", time="10:00:00"),
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
        goal_name="Fly 1000miles+ flight in MSFS2020"
    ))