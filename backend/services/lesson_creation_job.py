import logging
from sqlalchemy import select
from backend.core.database import AsyncSessionLocal
from backend.models.goal import Goal
from backend.repositories.objective_repository import ObjectiveRepository
from backend.repositories.multiple_choice_question_repository import MultipleChoiceQuestionRepository
from backend.repositories.multiple_choice_answer_repository import MultipleChoiceAnswerRepository
from backend.services.account_creation_tasks import gemini_generate_multiple_choice_questions
from backend.repositories.streak_day_repository import StreakDayRepository
from backend.utils.time_period import get_yesterday_date_range
from backend.utils.envs import NUM_QUESTIONS_PER_LESSON

logger = logging.getLogger(__name__)

async def run_lesson_creation_job():
    logger.info("Starting lesson creation job")
    
    async with AsyncSessionLocal() as db:
        try:
            objective_repo = ObjectiveRepository(db)
            mcq_repo = MultipleChoiceQuestionRepository(db)
            answer_repo = MultipleChoiceAnswerRepository(db)
            
            # 1. Get all goals (to find active students and their objectives)
            goals_stmt = select(Goal)
            goals_result = await db.execute(goals_stmt)
            all_goals = goals_result.scalars().all()
            
            yesterday_start, yesterday_end = get_yesterday_date_range()
            
            processed_count = 0
            generated_count = 0
            
            for goal in all_goals:
                try:
                    # Get latest objective for this goal
                    latest_objective = await objective_repo.get_latest_by_goal_id(goal.id)
                    if not latest_objective:
                        continue
                    
                    student_id = str(goal.student_id)
                    objective_id = str(latest_objective.id)
                    
                    streak_repo = StreakDayRepository(db)

                    yesterday_streak = await streak_repo.get_by_student_id_and_date(student.id, yesterday_start)

                    if not yesterday_streak:
                        logger.debug(f"Skipping student {student_id}: No activity yesterday.")
                        continue
                    
                    needs_work_questions = await mcq_repo.get_unanswered_or_wrong(
                        objective_id, student_id, limit=20
                    )
                    
                    accuracy_yesterday = await answer_repo.get_accuracy_by_date_range(
                        student_id, yesterday_start, yesterday_end
                    )
                    
                    if len(needs_work_questions) < 10 or accuracy_yesterday > 75.0:
                        logger.info(f"Generating new questions for student {student_id} (Obj: {objective_id})")
                        
                        mc_questions = gemini_generate_multiple_choice_questions(
                            objective_name=objective_name,
                            objective_description=objective_description,
                            previous_objectives=["This is the student's first objective ever"],
                            informations=["No relevant information to add"],
                            num_questions=NUM_QUESTIONS_PER_LESSON
                        )
                        generated_count += 1

                        for question in mc_questions.questions:
                            # Map choices list to individual option fields
                            if len(question.choices) < 4:
                                logger.warning(f"Question has fewer than 4 choices: {question.question}")
                                continue
                                
                            mcq = MultipleChoiceQuestion(
                                objective_id=objective_id,
                                question=question.question,
                                option_a=question.choices[0],
                                option_b=question.choices[1],
                                option_c=question.choices[2],
                                option_d=question.choices[3],
                                correct_answer_index=question.correct_answer_index,
                                ai_model=mc_questions.ai_model,
                            )
                            db.add(mcq)
                        
                        await db.commit()
                    
                    processed_count += 1
                    
                except Exception as e:
                    logger.error(f"Error processing lesson creation for goal {goal.id}: {e}", exc_info=True)
                    continue
            
            logger.info(f"Lesson creation job completed. Processed: {processed_count}, Generated for: {generated_count}")
            
        except Exception as e:
            logger.error(f"Error in lesson creation job: {e}", exc_info=True)
            raise