#TODO: num_per_lesson is deprecated
#Lessons will have mcq and subjective
#Will count time_per_questions instead, and sum up to hit 2min lessons
#Evaluations are just when user hits 95% mastery

from backend.core.config import settings

NUM_QUESTIONS_PER_LESSON = 12 #TODO: deprecated
NUM_QUESTIONS_PER_EVALUATION = 8
NUM_DIMENSIONS = 3072
EMBEDDING_MODEL = "gemini-embedding-2"
GEMINI_FAST_MODEL = "gemini-3.1-flash-lite"
GEMINI_PREMIUM_MODEL = "gemini-3.5-flash"
GOOGLE_PROJECT_ID = settings.GOOGLE_PROJECT_ID
GOOGLE_CLIENT_ID = settings.GOOGLE_CLIENT_ID

JWT_ISSUER = "https://goalsgetter.org/api/v1"
JWT_AUDIENCE = "https://goalsgetter.org/api/v1"

SECRET_KEY = "09d25e094faa6ca2556c818166b7a9563b93f7099f6f0f4caa6cf63b88e8d3e7"