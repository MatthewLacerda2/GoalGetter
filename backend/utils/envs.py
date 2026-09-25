# TODO: num_per_lesson is deprecated
# Lessons will have mcq and subjective
# Will count time_per_questions instead, and sum up to hit 2min lessons
# Evaluations are just when user hits 95% mastery

from backend.core.config import settings

# Deprecated: nothing reads it. Use QUESTIONS_PER_LESSON.
NUM_QUESTIONS_PER_LESSON = 12  # TODO: deprecated
# How many questions POST /goals/{goal_id}/lessons serves. Eight, because a
# lesson is meant to last about two minutes (#86) and the per-question time is
# what makes that measurable. It is a cap, not a floor: a bank shorter than this
# serves what it has. It also sets TARGET_SERVABLE, what a generation tops the
# bank up to (services/jobs/steps/questions.py).
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
