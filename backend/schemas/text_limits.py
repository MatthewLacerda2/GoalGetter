"""How long a text a client sends may be, when it ends up in a Gemini prompt (#217).

One constant per kind of text, and every request field that reaches Gemini reads
one of them - an over-long body is a 422 before any call is made. The measure is
characters. Generous for a student, bounded for the bill: each one is several
times what the app itself lets through or Gemini is asked to write.
"""

# What he wants to learn (the onboarding `prompt`). The app's field caps at 500.
GOAL_PROMPT_MAX_LENGTH = 1000

# One message to the tutor. About 350 words: a question with a paragraph of
# his own work pasted into it.
TUTOR_MESSAGE_MAX_LENGTH = 2000

# A line Gemini wrote and the app sends back: an onboarding question, the option
# he picked, the goal's name. Gemini is asked for 20 words at most.
GENERATED_LINE_MAX_LENGTH = 500

# The goal's description, written by the study-plan call and sent back to be
# stored. Gemini is asked for 60 words at most, in Markdown.
GENERATED_DESCRIPTION_MAX_LENGTH = 3000

# How many onboarding answers one request carries. Onboarding asks 6 questions.
ONBOARDING_ANSWERS_MAX_COUNT = 20
