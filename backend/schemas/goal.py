from pydantic import BaseModel, Field

class GoalCreationFollowUpQuestionsRequest(BaseModel):
    prompt: str = Field(..., description="The user's declaration of their goal")

class GoalCreationFollowUpQuestionsResponse(BaseModel):
    original_prompt: str = Field(..., description="The user's declaration of their goal")
    questions: list[str] = Field(..., description="The questions to ask the user to understand their goal")

class GoalFollowUpQuestionAndAnswer(BaseModel):
    question: str = Field(..., description="The question to ask the user to understand their goal")
    answer: str = Field(..., description="The user's answer to the question")

class GoalStudyPlanRequest(BaseModel):
    prompt: str = Field(..., description="The user's declaration of their goal")
    questions_answers: list[GoalFollowUpQuestionAndAnswer] = Field(..., description="The questions and answers to understand the user's goal")

class GoalStudyPlanResponse(BaseModel):
    goal_name: str = Field(..., description="The Goal defined by the Tutor for the user")
    goal_description: str = Field(..., description="The Description of the Goal defined by the Tutor for the user")
    first_objective_name: str = Field(..., description="The First Objective towards the Goal. Defined by the Tutor for the user")
    first_objective_description: str = Field(..., description="The Description of the First Objective towards the Goal. Defined by the Tutor for the user")
    milestones: list[str] = Field(..., description="The Milestones towards the Goal. Defined by the Tutor for the user")

class GoalFullCreationRequest(BaseModel):
    goal_name: str = Field(..., description="The Goal defined by the Tutor for the user")
    goal_description: str = Field(..., description="The Description of the Goal defined by the Tutor for the user")
    first_objective_name: str = Field(..., description="The First Objective towards the Goal. Defined by the Tutor for the user")
    first_objective_description: str = Field(..., description="The Description of the First Objective towards the Goal. Defined by the Tutor for the user")
    