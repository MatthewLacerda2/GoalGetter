from backend.core.config import settings

# How many questions one Gemini call is asked for. **The size of a batch, not
# of a lesson** (#135) - the two were the same number until #134 and are not the
# same thing: a lesson is two minutes, and how many questions that is comes from
# the student's own answering pace (six to twelve, services/lessons/pacing.py).
#
# Eight, in the user's own words: "pedir exatamente 8 e uma boa, nao sao
# perguntas demais nem de menos; pedir demais pode diminuir a performance, ainda
# mais quando nao temos contexto suficiente sobre o usuario". It is a fixed
# number and no longer a gap to fill, because the decision to generate is no
# longer about how full the bank is (services/lessons/generation.py).
QUESTIONS_PER_GENERATION = 8
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
