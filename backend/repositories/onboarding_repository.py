import logging
from datetime import datetime

from sqlalchemy import delete as sql_delete
from sqlalchemy import select

from backend.models.goal import Goal
from backend.models.onboarding_question import OnboardingQuestion
from backend.repositories.base import BaseRepository
from backend.services.onboarding.standard_questions import (
    STANDARD_QUESTIONS,
    SYSTEM_AUTHOR,
    StandardQuestion,
)

logger = logging.getLogger(__name__)

# The free-text row's question: what the start screen asks before any
# multiple-choice question exists. It is the student's own words, so no option
# was selected and `selected_option_index` stays NULL.
PROMPT_QUESTION = "What do you want to learn?"


class OnboardingRepository(BaseRepository[OnboardingQuestion]):
    """Where the onboarding waits until the chain turns it into a context (#88).

    The chain has to be able to *read* the onboarding, not be handed it: goal
    creation writes these rows and returns, and whichever run of the chain gets
    there first - the one goal creation fires, or tomorrow night's after that
    one failed - reads them. An input that is only an argument is lost the
    moment the call that carried it fails.

    **What the table holds and what the API sends.** `onboarding_questions` has
    four option columns; `POST /goals` sends only the option the student picked
    (`ObjectiveAnswer` in schemas/goal.py deliberately omits the rest). So a row
    records the chosen text in `option_a` with `selected_option_index = 0`, and
    leaves the three options it was never told about empty. Widening the request
    to carry all four is a frontend change and buys the prompt nothing: what the
    student did *not* pick says little about them.

    The **standard questions** (#132) are the one kind of row that does know all
    four: they are written by us, not generated, so the row carries every option
    and the true index of the one picked. `answer_of` is the single rule that
    reads any of the three shapes back, so nothing outside this file has to know
    which shape a row is in.

    **Who wrote the question** is `ai_model`: the Gemini model for the ones it
    generated, the literal `"system"` for the standard four and for the row
    holding the student's own words.

    **How long he took** is `total_seconds`, on every answered row of both
    kinds, as the app measured it; NULL when it sent none, and on the free-text
    row, which it does not time (#174).

    This is a *use* of a table that was created on every boot and read by nobody
    (#112). The schema changes since are `ai_model` (#132) and `total_seconds`
    (#174).
    """

    async def create(self, entity: OnboardingQuestion) -> OnboardingQuestion:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity

    async def save_onboarding(
        self, goal_id, prompt: str, answers: list[tuple[str, str, int | None]], ai_model: str
    ) -> list[OnboardingQuestion]:
        """Persist one goal's onboarding: the student's own words first, then
        one row per question they answered, as `(question, answer, seconds)`.

        `ai_model` is the model that wrote those questions; the prompt row is
        ours, so it is `"system"` whatever the rest were written by.
        """
        rows = [self._row(goal_id, PROMPT_QUESTION, prompt, None, SYSTEM_AUTHOR, None)]
        rows += [
            self._row(goal_id, question, answer, 0, ai_model, seconds)
            for question, answer, seconds in answers
        ]
        self.db.add_all(rows)
        await self.db.flush()
        return rows

    async def save_standard_answers(
        self, goal_id, answers: list[tuple[str, str, int | None]]
    ) -> list[OnboardingQuestion]:
        """Persist the answers to the standard questions, as `(question key,
        option key, seconds)`.

        A key neither side knows is dropped and logged rather than refused: the
        client can only have sent one this backend served, so an unknown key is
        a build older than the question list - and losing one fact about the
        student is never worth costing him the lesson he is on his way to.
        """
        rows = []
        for question_key, option_key, seconds in answers:
            resolved = _resolve(question_key, option_key)
            if resolved is None:
                logger.info("Standard onboarding: unknown key %s/%s", question_key, option_key)
                continue
            question, index = resolved
            rows.append(_standard_row(goal_id, question, index, seconds))
        self.db.add_all(rows)
        await self.db.flush()
        return rows

    async def get_by_id(self, entity_id: str) -> OnboardingQuestion | None:
        stmt = select(OnboardingQuestion).where(OnboardingQuestion.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_by_student(
        self, student_id, as_of: datetime | None = None
    ) -> list[OnboardingQuestion]:
        """Everything the student told us while creating any of their goals,
        oldest first. A context is written about the person (#87), so it reads
        every goal's onboarding, not one goal's.

        `as_of` reads the onboarding *as it stood* at that moment. Goal creation
        passes the instant it wrote its rows, so the batch it fires cannot see
        the standard questions the student is answering while it runs (#132);
        every later run passes nothing and sees all of them.
        """
        stmt = (
            select(OnboardingQuestion)
            .join(Goal, Goal.id == OnboardingQuestion.goal_id)
            .where(Goal.student_id == student_id)
            .order_by(OnboardingQuestion.created_at.asc())
        )
        if as_of is not None:
            stmt = stmt.where(OnboardingQuestion.created_at <= as_of)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def update(self, entity: OnboardingQuestion) -> OnboardingQuestion:
        await self.db.flush()
        return entity

    async def delete(self, entity_id: str) -> bool:
        stmt = sql_delete(OnboardingQuestion).where(OnboardingQuestion.id == entity_id)
        result = await self.db.execute(stmt)
        return result.rowcount > 0

    @staticmethod
    def answer_of(row: OnboardingQuestion) -> str:
        """What the student answered, whichever shape the row is in.

        No index means the free-text row, whose answer is the whole of
        `option_a`; otherwise it is the option the index points at. One rule, so
        a reader of the onboarding never has to know where a question came from.
        """
        if row.selected_option_index is None:
            return row.option_a
        options = [row.option_a, row.option_b, row.option_c, row.option_d]
        return options[row.selected_option_index]

    @staticmethod
    def _row(
        goal_id,
        question: str,
        answer: str,
        index: int | None,
        ai_model: str,
        seconds: int | None,
    ) -> OnboardingQuestion:
        return OnboardingQuestion(
            goal_id=goal_id,
            question=question,
            option_a=answer,
            option_b="",
            option_c="",
            option_d="",
            selected_option_index=index,
            ai_model=ai_model,
            total_seconds=seconds,
        )


def _standard_row(
    goal_id, question: StandardQuestion, index: int, seconds: int | None
) -> OnboardingQuestion:
    """A standard question's row: all four options, and the one picked."""
    texts = [option.text for option in question.options]
    return OnboardingQuestion(
        goal_id=goal_id,
        question=question.text,
        option_a=texts[0],
        option_b=texts[1],
        option_c=texts[2],
        option_d=texts[3],
        selected_option_index=index,
        ai_model=SYSTEM_AUTHOR,
        total_seconds=seconds,
    )


def _resolve(question_key: str, option_key: str) -> tuple[StandardQuestion, int] | None:
    """The standard question a key names, and the index of the option picked."""
    for question in STANDARD_QUESTIONS:
        if question.key != question_key:
            continue
        for index, option in enumerate(question.options):
            if option.key == option_key:
                return question, index
    return None
