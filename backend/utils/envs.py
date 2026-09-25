from backend.core.config import settings

# How many questions a lesson holds by default. Eight, because a lesson is meant
# to last about two minutes (#86). It is a cap, not a floor: a bank shorter than
# this serves what it has. It also sets TARGET_SERVABLE, what a generation tops
# the bank up to (services/jobs/steps/questions.py).
#
# The flat number is on its way out (#131): a lesson is two minutes, and how many
# questions that is depends on the student's own answering pace, with a floor of
# six. Until #134 computes it, this is the default that
# services/lessons/selection.py hands out - no caller names a count of its own.
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
