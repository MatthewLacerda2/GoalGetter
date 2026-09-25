"""How many questions two minutes is, for this student (#134).

**A lesson is two minutes, not eight questions.** Two minutes is what the user
decided and what the product is built on - short and daily is what keeps coming
back cheap, and more answers is also more evidence about him, so the count is
whatever fills the two minutes rather than a constant anybody chose.

So the count comes from his own pace: how long his answers actually take,
divided into two minutes. A student who thinks hard gets the floor; one who
reads fast gets more. Both spend two minutes.

**This is the only place the answering time is read.** It deliberately does not
reach `selection.py`: how long he took says nothing about whether a question is
right for him (the user, 2026-09-24), and keeping the duration out of that
module's signature is how that stays true rather than being remembered.
"""

from statistics import median

# Two minutes, in seconds. The lesson's whole budget.
LESSON_SECONDS = 120

# The floor the user set: never fewer than six questions, whatever the pace.
# Below six a lesson stops being a lesson - too little evidence to move a
# rating by anything meaningful, and too little to feel like a day of study.
MIN_QUESTIONS = 6

# The ceiling. Twice the floor, which is two minutes at ten seconds a question,
# and ten seconds is about as fast as a person can read a question, read four
# options and choose one. A pace under that is not a student reading, it is a
# student tapping - or a client that sent nonsense - and neither is a reason to
# hand him forty questions. To change it, measure accuracy against the
# per-answer seconds: the speed at which accuracy collapses to chance is the
# speed at which he has stopped reading, and that is the real ceiling.
MAX_QUESTIONS = 12

# How many of his most recent answers the pace is read from. Three lessons at
# the usual eight: recent enough to follow him as he speeds up on a goal, and
# long enough that one slow question does not resize tomorrow's lesson.
#
# A count, not a span of days, so it adapts at the same rate for the student who
# studies daily and the one who studies on Sundays - and so that a student
# coming back after a month is met at the pace he left at rather than at the
# floor. The thirty-day window in `selection.py` is about forgetting, which is a
# property of time; pace is a property of the person.
PACE_WINDOW = 24


def lesson_size(seconds: list[int]) -> int:
    """How many questions to serve, given his last answers' durations, newest first.

    A missing pace is the floor, not a guess: a student with no timed answers at
    all - his first lesson ever - gets `MIN_QUESTIONS`, because six is the one
    number that was decided and anything else would be an invention about a
    person we know nothing about.

    **The middle answer, not the mean.** These durations are two different
    things wearing one column: how long he thought, and how long the phone lay
    on the table. Nothing tells them apart, and the mean believes the second - a
    single interrupted question in a window of eight drags a fast student's
    average from 8 seconds to 22 and halves his next three lessons. The median
    ignores it, and for a student who is genuinely slow it answers exactly what
    the mean would, because then there is no second mode to ignore. That is the
    only reading of "his average answering time" that survives a student putting
    his phone down, which every student does.
    """
    timed = [taken for taken in seconds[:PACE_WINDOW] if taken and taken > 0]
    if not timed:
        return MIN_QUESTIONS
    return max(MIN_QUESTIONS, min(MAX_QUESTIONS, round(LESSON_SECONDS / median(timed))))
