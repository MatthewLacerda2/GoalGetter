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

# The placement (the user, 2026-09-26): what a new goal is given right after
# onboarding, and how many answers it must hold before the nightly run buys it
# anything more. One number for both on purpose.
#
# Eighteen is three lessons at the six-question floor - *"creio que ajuda bem a
# definir o quanto o usuário sabe"*. And until he has answered that many (answers,
# not distinct questions: one he answered twice counts twice), the app has not
# measured him yet, so there is nothing to write the next batch from.
PLACEMENT_SIZE = 18
NUM_DIMENSIONS = 3072
EMBEDDING_MODEL = "gemini-embedding-2"
GEMINI_FAST_MODEL = "gemini-3.5-flash-lite"
GEMINI_PREMIUM_MODEL = "gemini-3.8-flash"
GOOGLE_PROJECT_ID = settings.GOOGLE_PROJECT_ID
GOOGLE_CLIENT_ID = settings.GOOGLE_CLIENT_ID
YOUTUBE_API_KEY = settings.YOUTUBE_API_KEY

JWT_ISSUER = "https://goalsgetter.org/api/v1"
JWT_AUDIENCE = "https://goalsgetter.org/api/v1"
