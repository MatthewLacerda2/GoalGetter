from backend.utils.gemini.gemini_configs import get_client, get_gemini_config
from backend.services.gemini.onboarding.onboarding_prompts import get_goal_follow_up_questions_prompt, get_goal_study_plan_prompt
from backend.schemas.goal import GoalCreationFollowUpQuestionsRequest, GoalCreationFollowUpQuestionsResponse, GoalStudyPlanRequest, GoalStudyPlanResponse, GoalFollowUpQuestionAndAnswer

def get_gemini_follow_up_questions(initiation_request: GoalCreationFollowUpQuestionsRequest) -> GoalCreationFollowUpQuestionsResponse:
    
    client = get_client()
    model = "gemini-2.5-flash"
    full_prompt = get_goal_follow_up_questions_prompt(initiation_request.prompt)
    config = get_gemini_config(GoalCreationFollowUpQuestionsResponse.model_json_schema())
    
    response = client.models.generate_content(
        model=model, contents=full_prompt, config=config
    )
    
    json_response = response.text
    
    return GoalCreationFollowUpQuestionsResponse.model_validate_json(json_response)

def get_gemini_study_plan(study_plan_request: GoalStudyPlanRequest) -> GoalStudyPlanResponse:
    
    client = get_client()
    model = "gemini-2.5-flash"
    full_prompt = get_goal_study_plan_prompt(study_plan_request)
    config = get_gemini_config(GoalStudyPlanResponse.model_json_schema())
    
    response = client.models.generate_content(
        model=model, contents=full_prompt, config=config
    )
    
    json_response = response.text
    
    return GoalStudyPlanResponse.model_validate_json(json_response)

if __name__ == "__main__":
    prompt = """Me and my bro are thinking of tackling 3d printed welding. We know it's being done to rocket engines,
    but if we could do it to weld whatever else that'd be cool. We wouldn't come up with the designs, just take orders.
    Is it doable and how long would it take to create the robotics to do it? i just wanna make sure, by the time we arrive, we are still early adopters.
    how long would it take us to figure it out like, how to weld, the robots or machinery to be designed made programmed and put by us? both of us have a
    strong engineering and programming background but no idea about welding other than it's difficult (we heard it's a pain to others, hence we know of
    3d printed rockets and how good they are)"""
    
    print("🤖 Getting follow-up questions...")
    follow_up_request = GoalCreationFollowUpQuestionsRequest(prompt=prompt)
    follow_up_response = get_gemini_follow_up_questions(follow_up_request)
    
    print(f"\n📝 Original prompt: {follow_up_response.original_prompt}")
    print(f"\n❓ Found {len(follow_up_response.questions)} questions to ask you:")
    
    # Collect answers
    questions_answers = []
    for i, question in enumerate(follow_up_response.questions, 1):
        print(f"\n{i}. {question}")
        answer = input("Your answer: ").strip()
        questions_answers.append(GoalFollowUpQuestionAndAnswer(question=question, answer=answer))
    
    print("\n🎯 Generating your personalized study plan...")
    study_plan_request = GoalStudyPlanRequest(
        prompt=prompt,
        questions_answers=questions_answers
    )
    study_plan_response = get_gemini_study_plan(study_plan_request)
    
    print("\n" + "="*60)
    print("📚 YOUR STUDY PLAN")
    print("="*60)
    print(f"🎯 Goal: {study_plan_response.goal_name}")
    print(f"📖 Description: {study_plan_response.goal_description}")
    print(f"\n🚀 First Objective: {study_plan_response.first_objective_name}")
    print(f"📝 Description: {study_plan_response.first_objective_description}")
    print(f"\n🏁 Milestones:")
    for i, milestone in enumerate(study_plan_response.milestones, 1):
        print(f"   {i}. {milestone}")
    print("="*60)