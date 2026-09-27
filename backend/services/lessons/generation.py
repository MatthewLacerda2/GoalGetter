"""Whether tonight's generation is worth paying for (#135).

**Gemini writes the questions; arithmetic decides whether it is worth writing
any.** This is the arithmetic, and it is a read of the lesson selection's own
output (`selection.py`): the nightly run builds tomorrow's lesson exactly as the
endpoint would, and then asks a second question of the same eight - *is this
still hard enough for him?*

**It replaces counting rows (#91).** The old rule generated when the bank could
not serve two lessons, and the size of a bank says nothing: a student sitting on
two hundred questions he keeps missing does not need a two hundred and first, he
needs the ones he misses, again. A question stays in rotation until it is
answered right (the forgetting term), so the struggling student's bank already
holds tomorrow.

**Before either branch, the placement** (the user, 2026-09-26). A bank with
nothing in it is a goal created minutes ago: it gets `settings.PLACEMENT_SIZE` questions,
written by their own prompt to find where he is. And until the goal holds that
many *answers*, nothing more is bought - he has not been measured yet, so there
is nothing to write the next batch from.

**Then two branches and no third.**

- *He is missing a lot* - nothing is generated, and the night costs nothing.
- *It is too easy for him* - eight new questions, one step past what he holds.

**There is no floor.** A lesson is always served from what exists, so this never
has to rescue one; it is buying for the days after tomorrow.
"""

from dataclasses import dataclass
from statistics import fmean

from backend.core.config import settings
from backend.services.lessons.selection import TARGET_SCORE, TOLERANCE_BELOW, Ranked

# The predicted accuracy at or above which tomorrow's lesson counts as too easy,
# and below which the bank is already holding what he needs.
#
# **It is the hard edge of the band the selection scores against.** The target
# is `TARGET_SCORE` and one standard deviation on the hard side is
# `TOLERANCE_BELOW`, so a lesson predicted at 0.60 sits exactly on the edge of
# what the app is willing to put in front of him. Below it, the questions he
# would get tomorrow are already harder than the rule allows - that student is
# not short of material, he is short of practice.
#
# **It is also the user's own line, said in probability.** His sentence was "se
# passar de 40% [de erro], nao precisa gerar": more than 40% wrong is under 60%
# right, and 60% right is a mean `E` of 0.60, because `E` predicts the answers a
# student actually gets right - the lucky guesses included, since the 0.25 floor
# in `rasch.py` is what puts them there. So the two readings land on the same
# number from opposite directions.
#
# Note where that sits against **par**, which is not 0.5 here: a question at
# exactly the student's rating is answered right 62.5% of the time, a quarter of
# it luck. The user's line is therefore a touch *harder* than par - 0.60 is the
# chance of a question 23 rating points above him - which says his "40% wrong"
# means a lesson pitched at him or harder, not one he is failing at.
#
# To change it: measure the lesson-completion rate against this predicted
# accuracy. The line belongs where students stop finishing.
GENERATE_ABOVE = round(TARGET_SCORE - TOLERANCE_BELOW, 2)


@dataclass(frozen=True)
class Verdict:
    """What the run decided about one goal, and the sentence that says why.

    The reason is not decoration: the nightly run is watched by reading its log
    (#89), and what there is to watch here is which of the two branches each
    student's goal took and on what number.
    """

    generate: bool
    predicted: float | None
    reason: str
    # The goal's first batch: `settings.PLACEMENT_SIZE` questions from the placement
    # prompt instead of `settings.QUESTIONS_PER_GENERATION` from the lesson one.
    placement: bool = False


def decide(lesson: list[Ranked], answers: int) -> Verdict:
    """Whether to buy questions for a goal whose next lesson would be `lesson`.

    `lesson` is what `select_lesson` returned for tomorrow - the same entries the
    endpoint would serve - and the whole decision is the mean of the `expected`
    they carry. Nothing is counted, and nothing here needs a database or a
    clock, which is what makes the rule testable at the price of arithmetic.

    `answers` is how many answers the goal has ever received - a question
    answered twice counts twice.
    """
    if not lesson:
        return Verdict(
            True,
            None,
            f"placement: {settings.PLACEMENT_SIZE} questions, the bank is empty so this is the "
            "goal's first batch",
            placement=True,
        )
    if answers < settings.PLACEMENT_SIZE:
        return Verdict(
            False,
            None,
            f"nothing: {answers} answers, under the {settings.PLACEMENT_SIZE} that measure him",
        )

    predicted = fmean(entry.expected for entry in lesson)
    if predicted < GENERATE_ABOVE:
        return Verdict(
            False,
            predicted,
            f"nothing: tomorrow's {len(lesson)} predict {predicted:.2f} accuracy, under "
            f"{GENERATE_ABOVE:.2f} - the bank already holds what he is missing",
        )
    return Verdict(
        True,
        predicted,
        f"generating {settings.QUESTIONS_PER_GENERATION}, one step past what he holds: tomorrow's "
        f"{len(lesson)} predict {predicted:.2f} accuracy, at or over {GENERATE_ABOVE:.2f}",
    )
