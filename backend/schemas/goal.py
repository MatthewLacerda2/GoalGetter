from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict

class GoalCreationFollowUpQuestionsRequest(BaseModel):
    model_config = ConfigDict(description="Request model for generating follow-up questions to better understand a user's goal")
    
    prompt: str = Field(..., description="The user's declaration of their goal")

class GoalCreationFollowUpQuestionsResponse(BaseModel):
    model_config = ConfigDict(description="Response model containing the original prompt and generated follow-up questions")
    
    original_prompt: str = Field(..., description="The user's declaration of their goal")
    questions: list[str] = Field(..., description="The questions to ask the user to understand their goal")

class GoalFollowUpQuestionAndAnswer(BaseModel):
    model_config = ConfigDict(description="Model representing a question-answer pair for goal clarification")
    
    question: str = Field(..., description="The question to ask the user to understand their goal")
    answer: str = Field(..., description="The user's answer to the question")

class GoalStudyPlanRequest(BaseModel):
    model_config = ConfigDict(description="Request model for creating a study plan based on goal and follow-up responses")
    
    prompt: str = Field(..., description="The user's declaration of their goal")
    questions_answers: list[GoalFollowUpQuestionAndAnswer] = Field(..., description="The questions and answers to understand the user's goal")

class GoalStudyPlanResponse(BaseModel):
    model_config = ConfigDict(description="Response model containing the generated study plan with goal, objective, and milestones")
    
    goal_name: str = Field(..., description="The Goal defined by the Tutor for the user")
    goal_description: str = Field(..., description="The Description of the Goal defined by the Tutor for the user")
    first_objective_name: str = Field(..., description="The First Objective towards the Goal. Defined by the Tutor for the user")
    first_objective_description: str = Field(..., description="The Description of the First Objective towards the Goal. Defined by the Tutor for the user")
    milestones: list[str] = Field(..., description="The Milestones towards the Goal. Defined by the Tutor for the user")

class GoalFullCreationRequest(BaseModel):
    model_config = ConfigDict(description="Request model for creating a complete goal with all necessary details")
    
    goal_name: str = Field(..., description="The Goal defined by the Tutor for the user")
    goal_description: str = Field(..., description="The Description of the Goal defined by the Tutor for the user")
    first_objective_name: str = Field(..., description="The First Objective towards the Goal. Defined by the Tutor for the user")
    first_objective_description: str = Field(..., description="The Description of the First Objective towards the Goal. Defined by the Tutor for the user")

class GoalListItem(BaseModel):
    model_config = ConfigDict(description="Model representing a goal in a list")
    
    id: str = Field(..., description="The unique identifier of the goal")
    name: str = Field(..., description="The name of the goal")
    description: str = Field(..., description="The description of the goal")
    created_at: datetime = Field(..., description="When the goal was created")

class ListGoalsResponse(BaseModel):
    model_config = ConfigDict(description="Response model containing a list of goals for the current student")
    
    goals: list[GoalListItem] = Field(..., description="List of goals for the current student, ordered by latest objective update")
    