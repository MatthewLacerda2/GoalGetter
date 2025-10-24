from backend.models.objective import Objective
from backend.utils.envs import NUM_QUESTIONS_PER_LESSON
from backend.services.ollama.multiple_choice import ollama_generate_multiple_choice_questions
from backend.models.multiple_choice_question import MultipleChoiceQuestion
from backend.services.gemini.objective_notes.schema import GeminiObjectiveNotesList
from backend.services.gemini.objective_notes.objective_notes import gemini_define_objective_notes
from backend.models.objective_note import ObjectiveNote

def account_creation_tasks(objective: Objective, db) -> None:
    
    for i in range(4):
        create_mcqs(objective, db)
    
    create_notes(objective.name, objective.description, objective.id, db)    
    #TODO: add search_resources()    
    return

def create_mcqs(objective: Objective, db) -> None:
    
    ollama_mc_questions = ollama_generate_multiple_choice_questions(
        objective.name, objective.description, ["This is the student's first objective ever"], ["No relevant information to add"], NUM_QUESTIONS_PER_LESSON
    )
    
    for question in ollama_mc_questions.questions:
        mcq = MultipleChoiceQuestion(
            objective_id=objective.id,
            question=question.question,
            choices=question.choices,
            correct_answer_index=question.correct_answer_index,
        )
        db.add(mcq)
    
    db.commit()

def create_notes(obj_name: str, obj_desc: str, obj_id: str, db):
    
    gemini_notes: GeminiObjectiveNotesList = gemini_define_objective_notes(obj_name, obj_desc)
    
    for note in gemini_notes.notes:
        note = ObjectiveNote(
            objective_id = obj_id,
            title = note.title,
            info = note.info
        )
        db.add(note)
    
    db.commit()