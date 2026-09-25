from backend.core.config import settings

# What one lesson costs the bank, as the *generator* reckons it. It sets
# TARGET_SERVABLE, what a generation tops the bank up to, and how many questions
# one Gemini call is asked for (services/jobs/steps/questions.py).
#
# **It is no longer how many questions a lesson serves** (#134). A lesson is two
# minutes, and how many questions that is comes from the student's own answering
# pace - six to twelve, computed in services/lessons/pacing.py. Eight is the
# middle of that band, which is why it survives here as the generator's unit: a
# night that tops the bank up to two of these covers the widest lesson the
# pacing can ask for, plus a spare.
QUESTIONS_PER_LESSON = 8
NUM_QUESTIONS_PER_EVALUATION = 8
NUM_DIMENSIONS = 3072
EMBEDDING_MODEL = "gemini-embedding-2"
GEMINI_FAST_MODEL = "gemini-3.5-flash-lite"
GEMINI_PREMIUM_MODEL = "gemini-3.8-flash"
GOOGLE_PROJECT_ID = settings.GOOGLE_PROJECT_ID
GOOGLE_CLIENT_ID = settings.GOOGLE_CLIENT_ID
YOUTUBE_API_KEY = settings.YOUTUBE_API_KEY

JWT_ISSUER = "https://goalsgetter.org/api/v1"
JWT_AUDIENCE = "https://goalsgetter.org/api/v1"
