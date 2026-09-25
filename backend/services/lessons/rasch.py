"""The goal's rating, and where a question's difficulty comes from (#62).

The elo **is** Item Response Theory with one parameter. The logistic curve chess
uses is the Rasch model and the per-game update is gradient descent on its
likelihood, so adopting elo properly gives the app IRT without a second
framework:

    E = 0.25 + 0.75 / (1 + 10 ** ((b - theta) / 400))    his chance of being right
    theta' = theta + K * (S - E)                         S = 1 right, 0 wrong

`0.25` is the four options: a quarter of every right answer is luck. Without the
floor a guess pays rating and an easy question reads as hard.

**A question's difficulty is never stored, never tagged and never a column.**
`b` is whatever the student's own answers to that question say; a question nobody
has answered yet is worth the rating the goal had when it was generated, because
the generator was aiming at the student. Both fall out of `replay`, which walks
the goal's whole history in order.

Nothing here is random, and nothing is incremental: the rating is a function of
the answers and of nothing else, so recomputing it twice gives the same number,
and a lost update repairs itself on the next submission.
"""

import math
from dataclasses import dataclass

from backend.models.question import Question
from backend.repositories.student_answer_repository import AnswerRecord

# Four options, so a quarter of every right answer is luck.
GUESS = 0.25
# The elo point. 400 of them are 10:1 odds - the constant that makes a rating
# here mean what a rating means anywhere else.
SCALE = 400.0
# Must agree with goals.rating's column default (models/goal.py).
START_RATING = 1200

# K decays with evidence, the way a provisional chess rating does. The curve is
# hyperbolic - K_MIN + (K_MAX - K_MIN) * K_HALF / (K_HALF + answers) - so it
# falls fast while the evidence is thin and flattens once it is not:
#
#     answers seen    0     10     40    200    -> forever
#     K              40     34     25     15         10
#
# K_HALF is 40 answers: five lessons, a goal's first week. A lesson is eight
# answers, so a first lesson can move the rating some 40 points and a settled
# one some 15 - enough to still mean something, not enough for one bad evening
# to undo a month.
K_MAX = 40.0
K_MIN = 10.0
K_HALF = 40.0

# The pseudo-answers that hold a question at its anchor until it has a record of
# its own. Two of them: one answer is an anecdote (a lucky guess would make a
# hard question look middling), three would take a week of repeats to overcome.
PRIOR_ANSWERS = 2.0
# What the model expects of a question sitting exactly at the student: E when
# b == theta. The prior is "this question is worth what it was aimed at".
PRIOR_SCORE = GUESS + (1 - GUESS) / 2
# A question can be 400 * log10(99) ~ 798 points from its anchor and no further.
# Unbounded, a short unbroken run of right answers would put it at minus
# infinity; 798 points is already E = 0.99 against it, which is as read as any
# question gets.
SKILL_CLAMP = 0.99


@dataclass
class GoalRatings:
    """What the history says, once: the rating it leaves the student at, how
    much evidence produced it, and what each bank question is worth to him.

    `difficulty` is the whole bank, answered or not - the selection (#134) ranks
    by `expected_score(rating, difficulty[question_id])`.
    """

    rating: int
    answers_seen: int
    difficulty: dict


def expected_score(rating: float, difficulty: float) -> float:
    """The chance this student gets this question right: the Rasch curve, lifted
    onto the floor the four options put under it."""
    return GUESS + (1 - GUESS) / (1 + 10 ** ((difficulty - rating) / SCALE))


def k_factor(answers_seen: int) -> float:
    """How far one answer may move the rating, given how much is already known
    about the student on this goal."""
    return K_MIN + (K_MAX - K_MIN) * K_HALF / (K_HALF + answers_seen)


def difficulty(anchor: float, answered: int, right: int) -> float:
    """What `answered` attempts, `right` of them correct, say the question is worth.

    The share of the answers that is not luck is `(p - 0.25) / 0.75`, and the
    rating that share implies is the curve read backwards. With no answers at
    all it returns the anchor exactly, which is the rating the goal had when the
    question was generated.
    """
    observed = (right + PRIOR_ANSWERS * PRIOR_SCORE) / (answered + PRIOR_ANSWERS)
    skill = (observed - GUESS) / (1 - GUESS)
    skill = min(max(skill, 1 - SKILL_CLAMP), SKILL_CLAMP)
    return anchor + SCALE * math.log10((1 - skill) / skill)


def replay(
    bank: list[Question], answers: list[AnswerRecord], start: int = START_RATING
) -> GoalRatings:
    """Walk one goal's whole history, oldest answer first, and arrive at today.

    Every answer is one update, because the answer is the event that carries
    information - there is no lesson row to hang a delta on (#131), and eight
    answers are eight pieces of evidence, not one.

    A question is anchored at the rating the student had when it was generated,
    which is why the walk is in time order: the anchor is read off the rating as
    the walk passes the question's `created_at`. An answer is scored against
    what its question's *earlier* answers said, never against its own outcome.
    """
    rating = float(start)
    born = sorted(bank, key=lambda question: (question.created_at, str(question.id)))
    anchors: dict = {}
    tally: dict = {}
    pending, seen = 0, 0

    for record in answers:
        while pending < len(born) and born[pending].created_at <= record.answered_at:
            anchors[born[pending].id] = rating
            pending += 1
        anchors.setdefault(record.question_id, rating)
        answered, right = tally.get(record.question_id, (0, 0))
        expected = expected_score(rating, difficulty(anchors[record.question_id], answered, right))
        rating += k_factor(seen) * ((1.0 if record.correct else 0.0) - expected)
        tally[record.question_id] = (answered + 1, right + int(record.correct))
        seen += 1

    for question in born[pending:]:
        anchors[question.id] = rating
    return GoalRatings(
        rating=round(rating),
        answers_seen=seen,
        difficulty={
            question.id: difficulty(anchors[question.id], *tally.get(question.id, (0, 0)))
            for question in bank
        },
    )
