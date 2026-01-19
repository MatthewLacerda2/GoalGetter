import pytest
# Import parent package first to ensure Python recognizes the correct package structure
import backend.services.ollama.chat
from backend.services.ollama.chat.chat import ollama_messages_generator
from backend.services.ollama.chat.schema import StudentContextToChat, OllamaChatMessage, OllamaChatResponse


def test_ollama_messages_generator():
    """Test ollama_messages_generator with example data - calls real Ollama API"""
    messages = [
        OllamaChatMessage(message="What are you doing?", role="model", time="10:00:13"),
        OllamaChatMessage(message="Hey is ma checklist right? Its for turning on the Cessna 150", role="user", time="10:00:00"),
        OllamaChatMessage(message="Im tryna remember how to turn it on", role="user", time="10:00:23"),
        OllamaChatMessage(message="- RPM: 100%, Fuel Flow: 100%\n- Battery: ON\n- Alternator: ON\n- Ignition: ON\n- Press Turn On", role="user", time="10:00:10"),
        OllamaChatMessage(message="No, this checklist is incorrect.", role="model", time="10:00:00"),
        OllamaChatMessage(message="RPM and Fuel Flow are not settings you adjust to 'turn on' the plane. Those are readouts or power settings used after the engine is running.", role="model", time="10:00:00"),
        OllamaChatMessage(message="You're missing critical steps like setting the parking brake, fuel selector, mixture, and throttle properly. You also need to prime the engine.", role="model", time="10:00:00"),
        OllamaChatMessage(message="'Press Turn On' is too vague. You need to engage the starter.", role="model", time="10:00:00"),
        OllamaChatMessage(message="You need to consult the Pilot's Operating Handbook (POH) for the Cessna 150. That will give you the precise, correct, and safe startup procedure. Guessing leads to mistakes.", role="model", time="10:00:00"),
    ]
    
    contexts = [
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
    ]
    
    result = ollama_messages_generator(
        messages=messages,
        contexts=contexts,
        objective_name="Learn how to start a plane",
        objective_description="Knowledge of how to turn on and start a plane by heart",
        goal_name="Fly 1000miles+ flight in MSFS2020"
    )
    
    assert isinstance(result, OllamaChatResponse)
    assert len(result.messages) > 0
