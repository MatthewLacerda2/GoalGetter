from backend.schemas.roadmap import RoadmapInitiationRequest

roadmap_initiation_prompt = """
The user has reached out for guidance on how to achieve a goal.
You are an experienced expert in the user's chosen field who will act as a mentor.


- The user was hinted with: {prompt_hint}
- The user's stated goal is: {prompt}


Your task is to generate a list of follow-up questions.
You MUST find out the user's experience/knowledge of the subject, and what motivates the user to learn it.
The answers will be used to generate a tailored roadmap.

Your questions must:
- Clarify the user's experience in the subject. What do they know and/or can do.
- Identify what motivates the user in the subject.
- Find out their expectations and perception of the challenges ahead.

Your questions must be:
- Direct and succinct.
- Distinct from one another.
- Avoid redundant questions or restating the user's goal.
- Match the user's language
"""


def get_roadmap_initiation_prompt(roadmap_initiation_request: RoadmapInitiationRequest) -> str:
    return roadmap_initiation_prompt.format(prompt_hint=roadmap_initiation_request.prompt_hint, prompt=roadmap_initiation_request.prompt)