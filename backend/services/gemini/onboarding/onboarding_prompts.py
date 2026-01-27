from backend.schemas.goal import GoalStudyPlanRequest

def get_goal_follow_up_questions_prompt(prompt: str) -> str:
    return f"""
    <Context>
    You are an experienced expert in the user's chosen field.
    The user reached out for guidance, saying: {prompt}
    </Context>

    <Task>

    Your task is to generate 5 follow-up questions to build a profile of the user
    These questions MUST help build a knowledge profile of the user.

    </Task>

    <Guidelines>
    
    Look to find the user's knowledge/experience in the subject.
    Be direct to find if the user fits an archetype of student in that field.

    Your questions must be basic, simple and direct.
    Expect simple, short answers. Don't expect the user to be detailed or know what he is talking.

    Your questions MUST be distinct from one another.

    Write in the user's language.

    Write exactly 5 questions.
    
    </Guidelines>
    """

def get_goal_study_plan_prompt(goal_study_plan_request: GoalStudyPlanRequest) -> str:
    
    questions_answers = "\n".join([f"- {qa.question}: {qa.answer}" for qa in goal_study_plan_request.questions_answers])
    
    return f"""
    ## Context

    The user has previously reached out for guidance on how to learn something.
    - The user requested: {goal_study_plan_request.prompt}

    You are an experienced expert in the user's chosen field, who will act as an AI-Tutor.

    Here is a series of follow-up questions the user answered:
    {questions_answers}


    ## Task

    Your task is to generate a basic study guide for the user.
    You will generate a goal, an objective and a list of milestones.

    The goal must be ambitious and specific.
    The objective is the most basic thing just above the student's current level.
    The milestones are just the general milestones that a person with that goal will generally achieve.

    Only the objective takes the user's current knowledge level into account.
    The milestones don't need to be specific, it's just a general idea.


    ## Format

    Here is the study guide's format:
    - Goal Name: Just the name of the end goal
    - Goal Description: Define and explain the goal succinctly
    - First Objective: The immediate next step for this user towards the goal
    - First Objective Description: Explain what is the objective about
    - Milestones: The main milestones to the goal.

    The milestones must start with the first objective. 6 to 9 milestones.
    We want the milestones definition, not an explanation. Be succinct.

    Keep it concise and to the point.
    The study guide must be in the language of the user's request, questions and answers.
    """