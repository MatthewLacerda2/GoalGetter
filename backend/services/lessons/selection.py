"""Which questions a lesson serves, and why those (#134).

**Gemini writes the questions; arithmetic decides which ones appear.** This runs
several times a day per student, so as a model call it would be the app's
largest cost and its least predictable behaviour. Everything below is a formula
over rows the app already has.

Every question of the goal's bank is given a score, and the top `size` are
served. Four terms, each of them a number in [0, 1] so that the weights beside
them are comparable, and one wired at zero:

1. **Threshold** - how close his chance of getting it right sits to 0.75.
2. **Forgetting** - how due it is, given when he last answered it and how well.
3. **Coverage** - how far it is from what this lesson already holds, and how
   close it is to the goal's current frontier.
4. **Novelty** - a flat bonus for a question he has never answered.
5. **Context** - how close it is to what the app has written about him. Weight
   zero, on purpose: see `WEIGHT_CONTEXT`.

**Cold start is not a special case, and there is no branch for it.** A student
with no answers has a bank anchored at the rating it was born with, so `E` ties
everywhere and the threshold term is the same for every question; the forgetting
term is zero for all of them; and the ranking falls through to novelty and
coverage, which is "serve what we have, and do not serve the same thing twice".

**Deterministic, and the lesson is the proof.** No sampling, no shuffle, no
clock read except the one passed in. Ties break by the question's `created_at`
and then its id, so the same history at the same hour is the same lesson - which
is also the only way this is honestly testable.
"""

import math
from dataclasses import dataclass
from datetime import datetime

from backend.core import clock
from backend.models.question import Question
from backend.models.student_context import StudentContext
from backend.repositories.student_answer_repository import AnswerRecord
from backend.services.lessons.rasch import GUESS, expected_score, replay
from backend.utils.vectors import cosine

# Where content belongs: his chance of answering correctly, aimed at 0.75.
#
# Classical Item Response Theory would aim at 0.5, which measures the student
# best. **0.75 is a product decision and not a measurement one**: we are not
# optimising how precisely we know him, we are optimising that he comes back
# tomorrow, and a lesson he gets right three times in four is one he finishes.
#
# Note what 0.75 means under the guessing floor (`rasch.py`): par for a question
# sitting exactly at the student is 0.625, not 0.5, because a quarter of every
# right answer is luck. So the target question sits about 120 rating points
# *below* him, and "at the threshold" is "he genuinely knows two thirds of it",
# not "it is harder than he is".
TARGET_SCORE = 0.75

# How wide the band around the target is: one standard deviation of the bell the
# term is scored on, on the hard side of it. At 0.15, a question he has a 60%
# chance on still scores 0.6 and one he has a coin's chance on scores under 0.25
# - "never handed more than he can take", written as a curve.
TOLERANCE_BELOW = 0.15

# And on the easy side, which is **not** the same width, because `E` does not
# measure the two failures on the same scale. Below the target there is half a
# unit of room (0.75 down to the 0.25 guessing floor); above it there is a
# quarter (0.75 up to certainty). A bell symmetric in `E` would therefore read a
# question he gets right 85% of the time as nearly ideal, when in fact the whole
# of "he already knows this" lives in that quarter.
#
# So one standard deviation is the same *fraction* of the room available on its
# side - which makes this derived rather than chosen, and leaves `TOLERANCE_BELOW`
# the only width anybody picked. To change either: measure the lesson-completion
# rate against `E`; the width should be the band inside which students finish.
TOLERANCE_ABOVE = TOLERANCE_BELOW * (1.0 - TARGET_SCORE) / (TARGET_SCORE - GUESS)

# How long the app looks back when asking what he remembers and what he keeps
# getting wrong - the user's own call. Older answers still move the rating,
# which is cumulative by nature; they just stop arguing about what to serve
# today. It also caps the gap in the forgetting term: a question untouched for
# longer than this is simply "due", and there is nothing more to say about it.
WINDOW_DAYS = 30.0

# The memory horizon of a question he has just got wrong, in days. One day,
# because that is the user's own rule read literally: a question he missed is
# due again tomorrow.
HORIZON_DAYS = 1.0

# What each consecutive correct answer multiplies the horizon by. 2.5 is
# SuperMemo's default ease factor, and the schedule it produces is the familiar
# one: wrong -> tomorrow, right once -> in 2.5 days, twice -> in 6, three times
# -> in 16, four times -> parked for well over a month. That is the user's
# example in a constant: "answered A wrong, then B right, then A wrong again -
# a sign he did not really learn it - then B three times".
HORIZON_GROWTH = 2.5

# What a term is worth when there is nothing to compute it from: an embedding
# the nightly backfill has not reached yet (#96), a lesson with nothing chosen
# so far. The midpoint, so a missing vector neither argues for a question nor
# against it - a neutral of 1.0 would quietly make un-embedded questions the
# most diverse things in the bank, and a neutral of 0.0 the least.
NEUTRAL = 0.5

# The weights. They are ratios against the threshold, which is the app's own
# rule and therefore the unit everything else is quoted in.
#
# The threshold decides what he *can* take; the others decide what is worth
# serving among the things he can. Each of them is smaller than the threshold on
# its own, and among questions he has never seen - where forgetting is zero for
# everything - the most the others can pay together is 0.9 against the
# threshold's 1.0, so nothing new is ever promoted over something that fits him
# better. Among questions he *has* answered, forgetting is allowed to argue
# back, which is the whole of what revision means.
WEIGHT_THRESHOLD = 1.0

# Forgetting is worth nearly as much as the threshold, and the two almost never
# argue. A question he has never answered has nothing to forget, so among new
# material the threshold decides alone; a question he *has* answered is a
# question the app already judged he could take, and what is left to decide is
# whether he has finished with it. So this weight does not dilute the threshold
# rule - it sets how hard revision competes with new material, and 0.8 says a
# question he got wrong yesterday is worth more than one he has settled, which
# is the behaviour the user asked for in so many words.
#
# It also has to be this large to overcome a circularity: getting a question
# wrong is the only evidence there is that it is hard, so the same wrong answer
# both raises the threshold term's estimate of its difficulty and raises its
# due-ness. Under 0.57 the first cancels the second and a missed question never
# returns. To change it: measure whether the second attempt at a missed question
# is more often right than the first - if it is not, the horizon is wrong before
# the weight is.
WEIGHT_FORGETTING = 0.8

# Coverage is a corrective, not a driver. It breaks a tie between two questions
# of the same level and the same due-ness, and it is the only thing standing
# between a student and eight rewordings of one question. Half of it is distance
# from what this lesson already holds, half is closeness to the frontier, so
# each half is worth at most 0.2 - enough to reorder equals, never enough to
# promote a question he cannot take. To change it: measure the spread of the
# served questions' embeddings against how much of the lesson he finishes.
WEIGHT_COVERAGE = 0.4

# A question he has never answered carries the most information there is: it is
# the only kind whose difficulty is still a guess. At 0.5 against a forgetting
# weight of 0.8, a repeat has to be about one memory-horizon overdue (63% decayed)
# before it outranks a question he has never seen - unfinished business wins,
# but only once it has actually gone stale. To change it: measure how much a
# first answer moves a rating against how much a repeat does.
WEIGHT_NOVELTY = 0.5

# Zero, deliberately (#134). The term is wired and computed: how close the
# question sits to what Gemini wrote about this student - what he knows
# (`state`) and how he thinks (`metacognition`). It is the weakest of the
# signals, it is a vector of a sentence about a person rather than of anything
# he did, and there is nothing yet to measure it against. Turning it on is a
# later decision taken with data in hand, not a number guessed here.
WEIGHT_CONTEXT = 0.0

# How many decimal places two scores must agree on to count as the same score.
# Nine is far beyond any difference the weights can express and far inside
# float noise, so a genuine tie ties and is broken by `created_at` and id.
TIE_PLACES = 9


@dataclass(eq=False)
class Ranked:
    """One bank question, and what each term of the ranking says about it.

    Everything except the diversity half of coverage is fixed before the lesson
    is built. Diversity is marginal - it depends on what has already been
    chosen - which is why it arrives at `score` instead of living here.

    `eq=False`: two entries are the same entry only if they are the same
    object. `_fill` removes the entry it just picked from the candidates, and
    two different questions scoring identically - which is the ordinary case at
    cold start - must not be able to stand in for one another there.
    """

    question: Question
    threshold: float
    forgetting: float
    frontier: float
    novelty: float
    context: float

    def score(self, diversity: float) -> float:
        """What this question is worth to a lesson that already holds the
        questions `diversity` was measured against."""
        coverage = (self.frontier + diversity) / 2
        return round(
            WEIGHT_THRESHOLD * self.threshold
            + WEIGHT_FORGETTING * self.forgetting
            + WEIGHT_COVERAGE * coverage
            + WEIGHT_NOVELTY * self.novelty
            + WEIGHT_CONTEXT * self.context,
            TIE_PLACES,
        )


@dataclass
class Recall:
    """What the window says about one question: when he last answered it at all,
    and how many correct answers in a row end its record inside the window.

    The streak is read from the window only - thirty days is how far back "what
    he keeps getting wrong" reaches - while the moment is read from the whole
    history, because a question he last saw in March is due whether or not the
    window can see it.
    """

    last_at: datetime | None = None
    streak: int = 0


def threshold_score(expected: float) -> float:
    """How well a question with this chance of being answered right sits at the
    threshold: a bell centred on `TARGET_SCORE`, narrower on the easy side.

    Too easy is waste and too hard is harm, and the bell says so in different
    widths rather than in a branch anybody has to remember.
    """
    spread = TOLERANCE_BELOW if expected <= TARGET_SCORE else TOLERANCE_ABOVE
    return math.exp(-((expected - TARGET_SCORE) ** 2) / (2 * spread**2))


def forgetting_score(recall: Recall, now: datetime) -> float:
    """How due a question is: `1 - exp(-dt / h)`, the complement of what he is
    expected to still hold.

    `h` grows by `HORIZON_GROWTH` with every consecutive correct answer and
    falls back to `HORIZON_DAYS` on a wrong one, so a question he has settled
    fades out of the rotation and one he has just missed comes straight back.

    A question he has never answered scores zero here and collects the novelty
    bonus instead: there is no memory to have decayed, and paying it twice for
    the same fact would drown every repeat the student actually needs.
    """
    if recall.last_at is None:
        return 0.0
    elapsed = (now - recall.last_at).total_seconds() / 86400.0
    elapsed = min(max(elapsed, 0.0), WINDOW_DAYS)
    return 1.0 - math.exp(-elapsed / (HORIZON_DAYS * HORIZON_GROWTH**recall.streak))


def affinity(left, right) -> float:
    """Closeness of two embeddings as a term in [0, 1], `NEUTRAL` when there is
    nothing to compare.

    Negative similarity is floored at zero: a question pointing away from the
    frontier is not about it, which is the same thing as being unrelated to it.
    """
    similarity = cosine(left, right)
    return NEUTRAL if similarity is None else max(0.0, similarity)


def read_recall(history: list[AnswerRecord], now: datetime) -> dict:
    """The window's reading of every question the student has ever answered.

    One pass, oldest answer first, which is the order the repository returns.
    """
    inside = now.timestamp() - WINDOW_DAYS * 86400.0
    recalls: dict = {}
    for record in history:
        recall = recalls.setdefault(record.question_id, Recall())
        recall.last_at = clock.as_utc(record.answered_at)
        if recall.last_at.timestamp() >= inside:
            recall.streak = recall.streak + 1 if record.correct else 0
    return recalls


def context_affinity(question: Question, context: StudentContext | None) -> float:
    """How close a question sits to what the app has written about the student.

    Averaged over the two readings that have a vector, so a context the backfill
    has half-filled still says something. Wired at `WEIGHT_CONTEXT`, which is
    zero.
    """
    if context is None:
        return NEUTRAL
    vectors = [context.state_embedding, context.metacognition_embedding]
    scored = [cosine(question.text_embedding, vector) for vector in vectors]
    measured = [max(0.0, value) for value in scored if value is not None]
    return sum(measured) / len(measured) if measured else NEUTRAL


def rank_bank(
    bank: list[Question],
    history: list[AnswerRecord],
    frontier=None,
    context: StudentContext | None = None,
    now: datetime | None = None,
) -> list[Ranked]:
    """What every question of the bank is worth to this student right now, in the
    bank's own order.

    Separate from serving a lesson because it answers a second question the app
    has to ask: **is this bank still good enough** (#135). A bank whose entries
    all score low is a bank that has run out of things at his threshold, which is
    what makes a generation worth paying for - and that is read off these terms,
    not guessed from a count of unanswered rows.
    """
    moment = clock.as_utc(now if now is not None else clock.now())
    ratings = replay(bank, history)
    recalls = read_recall(history, moment)
    target = frontier.definition_embedding if frontier is not None else None
    return [
        Ranked(
            question=question,
            threshold=threshold_score(
                expected_score(ratings.rating, ratings.difficulty[question.id])
            ),
            forgetting=forgetting_score(recalls.get(question.id, Recall()), moment),
            frontier=affinity(question.text_embedding, target),
            novelty=0.0 if question.id in recalls else 1.0,
            context=context_affinity(question, context),
        )
        for question in bank
    ]


def select_lesson_questions(
    bank: list[Question],
    history: list[AnswerRecord],
    size: int,
    frontier=None,
    context: StudentContext | None = None,
    now: datetime | None = None,
) -> list[Question]:
    """The `size` questions this student should see next, best first.

    `size` is a **cap, not a floor**: a bank shorter than a lesson serves what it
    has. A student whose bank is empty has just created a goal, and the endpoint
    tells him so with a 409; a bank that is short but not empty means last
    night's generation came back thin, and refusing would turn one bad night at
    Gemini into a lost day of study. The bank only grows, so a short lesson
    repairs itself.

    `frontier` is the goal's current `Frontier` (#133) - where he is being taken,
    never `goals.description`, which is only what he asked for on day one.
    """
    return _fill(rank_bank(bank, history, frontier, context, now), size)


def _fill(ranked: list[Ranked], size: int) -> list[Question]:
    """Take the best question, then the best *given that one*, and so on.

    Greedy rather than a single sort, because coverage is marginal: whether a
    question is a reworded duplicate is a question about the lesson being built,
    not about the bank. Greedy is still deterministic - at every step the choice
    is the maximum of a fixed set, and equal scores are settled by the order the
    candidates were put in, which is `created_at` then id.
    """
    candidates = sorted(
        ranked, key=lambda entry: (entry.question.created_at, str(entry.question.id))
    )
    nearest: dict = {}
    chosen: list[Question] = []
    while candidates and len(chosen) < size:
        best = min(candidates, key=lambda entry: -entry.score(_diversity(nearest, entry)))
        chosen.append(best.question)
        candidates.remove(best)
        for entry in candidates:
            similarity = cosine(entry.question.text_embedding, best.question.text_embedding)
            if similarity is not None:
                key = entry.question.id
                nearest[key] = max(nearest.get(key, 0.0), similarity)
    return chosen


def _diversity(nearest: dict, entry: Ranked) -> float:
    """How unlike everything already chosen this question is. `NEUTRAL` while
    nothing has been compared to it - an empty lesson, or a question the nightly
    backfill has not embedded yet - so a missing vector cannot pass for novelty.
    """
    closest = nearest.get(entry.question.id)
    return NEUTRAL if closest is None else 1.0 - min(1.0, max(0.0, closest))
