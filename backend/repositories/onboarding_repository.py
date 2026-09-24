from sqlalchemy import delete as sql_delete
from sqlalchemy import select

from backend.models.goal import Goal
from backend.models.onboarding_question import OnboardingQuestion
from backend.repositories.base import BaseRepository

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

    This is a *use* of a table that was created on every boot and read by nobody
    (#112), not a schema change - no column is added, dropped or altered.
    """

    async def create(self, entity: OnboardingQuestion) -> OnboardingQuestion:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity

    async def save_onboarding(
        self, goal_id, prompt: str, answers: list[tuple[str, str]]
    ) -> list[OnboardingQuestion]:
        """Persist one goal's onboarding: the student's own words first, then
        one row per question they answered."""
        rows = [self._row(goal_id, PROMPT_QUESTION, prompt, None)]
        rows += [self._row(goal_id, question, answer, 0) for question, answer in answers]
        self.db.add_all(rows)
        await self.db.flush()
        return rows

    async def get_by_id(self, entity_id: str) -> OnboardingQuestion | None:
        stmt = select(OnboardingQuestion).where(OnboardingQuestion.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_by_student(self, student_id) -> list[OnboardingQuestion]:
        """Everything the student told us while creating any of their goals,
        oldest first. A context is written about the person (#87), so it reads
        every goal's onboarding, not one goal's."""
        stmt = (
            select(OnboardingQuestion)
            .join(Goal, Goal.id == OnboardingQuestion.goal_id)
            .where(Goal.student_id == student_id)
            .order_by(OnboardingQuestion.created_at.asc())
        )
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
    def _row(goal_id, question: str, answer: str, index: int | None) -> OnboardingQuestion:
        return OnboardingQuestion(
            goal_id=goal_id,
            question=question,
            option_a=answer,
            option_b="",
            option_c="",
            option_d="",
            selected_option_index=index,
        )
