import random

# The random elo is a placeholder the user asked for ("put a random elo") until
# the elo design (#62) lands. The +-20 span matches the scale of the old mock
# on the finish screen (debug/mock_lesson_controller.dart).
RANDOM_ELO_SPAN = 20


def lesson_elo_delta(rating: int, accuracy: float) -> int:
    """The signed change a finished lesson applies to `goals.rating`.

    Random for now, and on purpose: this one function is what #62 replaces.
    `rating` and `accuracy` (0..100) are the inputs a real formula will need;
    the random version ignores them.
    """
    return random.randint(-RANDOM_ELO_SPAN, RANDOM_ELO_SPAN)
