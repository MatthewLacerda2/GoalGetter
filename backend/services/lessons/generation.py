"""Whether tonight's generation is worth paying for, and what it aims at (#135).

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

**Two branches and no third.**

- *He is missing a lot* - nothing is generated, and the night costs nothing.
- *It is too easy for him* - eight new questions, aimed above where he is now.

**There is no floor.** A lesson is always served from what exists, so this never
has to rescue one; it is buying for the days after tomorrow. The one exception
is not a floor either: a bank with nothing in it is a goal created minutes ago,
and its first batch is the whole reason the chain runs at all.
"""

from dataclasses import dataclass
from statistics import fmean

from backend.services.lessons.rasch import K_MIN
from backend.services.lessons.selection import TARGET_SCORE, TOLERANCE_BELOW, Ranked
from backend.utils.envs import QUESTIONS_PER_GENERATION

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

# How far above his rating a generated batch aims, in rating points. It reaches
# the prompt as this number and never as the word "harder".
#
# **Above him at all** because this batch is not tomorrow's lesson - tomorrow is
# already served from the bank. It is the bank for the days after, and the only
# student who reaches this branch is one whose rating is climbing. A batch
# written for tonight's rating is behind him by the time he gets to it.
#
# **This far** because that is what the batch itself pays him: eight answers, at
# the accuracy this gate fires at, move a rating by
# `QUESTIONS_PER_GENERATION * K * (1 - GENERATE_ABOVE)` points. `K_MIN` is the
# floor a settled student ends at, so it is the smallest honest reading of
# "where he will be"; a provisional student moves four times as far, and aiming
# at *that* would overshoot everyone who is not new.
#
# It reads small on purpose. The hard edge of what the selection will serve is
# only 23 points above him, so 32 is already at the limit of what the app would
# put in front of him - anything in the hundreds would buy questions the
# selection then refuses to serve, which is the same as not buying them.
#
# To change it: measure the first-attempt accuracy on generated questions
# against this margin. It is right when a fresh batch is answered at about
# `TARGET_SCORE` after the rating has caught up with it.
GENERATION_MARGIN = round(QUESTIONS_PER_GENERATION * K_MIN * (1 - GENERATE_ABOVE))


@dataclass(frozen=True)
class Verdict:
    """What the run decided about one goal, and the sentence that says why.

    The reason is not decoration: the nightly run is watched by reading its log
    (#89), and what there is to watch here is which of the two branches each
    student's goal took and on what number.
    """

    generate: bool
    predicted: float | None
    target: int
    reason: str


def decide(lesson: list[Ranked], rating: int) -> Verdict:
    """Whether to buy questions for a goal whose next lesson would be `lesson`.

    `lesson` is what `select_lesson` returned for tomorrow - the same entries the
    endpoint would serve - and the whole decision is the mean of the `expected`
    they carry. Nothing is counted, and nothing here needs a database or a
    clock, which is what makes the rule testable at the price of arithmetic.
    """
    target = rating + GENERATION_MARGIN
    if not lesson:
        return Verdict(
            True,
            None,
            target,
            f"generating {QUESTIONS_PER_GENERATION} at difficulty {target}: the bank is "
            "empty, so this is the goal's first batch",
        )

    predicted = fmean(entry.expected for entry in lesson)
    if predicted < GENERATE_ABOVE:
        return Verdict(
            False,
            predicted,
            target,
            f"nothing: tomorrow's {len(lesson)} predict {predicted:.2f} accuracy, under "
            f"{GENERATE_ABOVE:.2f} - the bank already holds what he is missing",
        )
    return Verdict(
        True,
        predicted,
        target,
        f"generating {QUESTIONS_PER_GENERATION} at difficulty {target}: tomorrow's "
        f"{len(lesson)} predict {predicted:.2f} accuracy, at or over {GENERATE_ABOVE:.2f}",
    )
