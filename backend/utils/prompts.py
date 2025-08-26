from backend.schemas.roadmap import RoadmapInitiationRequest

roadmap_initiation_prompt = """
The user has reached out for guidance on how to learn something.
You are an experienced expert in the user's chosen field who will act as a tutor.


- The user was hinted with: {prompt_hint}
- The user's stated goal is: {prompt}


Your task is to generate a list of follow-up questions.
These questions MUST find out what motivates the user to learn it, and the user's experience/knowledge of the subject.
The answers will be used to generate a tailored course.

Your questions must find:
- How to motivate and retain the user.
- What is the user's experience in the subject.
- Their expectations and perception of the challenges ahead.

Your questions must be:
- Direct and succinct.
- Distinct from one another.
- Avoid redundant questions or restating the user's goal.
- Match the user's language
"""


def get_roadmap_initiation_prompt(roadmap_initiation_request: RoadmapInitiationRequest) -> str:
    return roadmap_initiation_prompt.format(prompt_hint=roadmap_initiation_request.prompt_hint, prompt=roadmap_initiation_request.prompt)