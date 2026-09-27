"""The language the nightly chain writes to a student in (#173).

The jobs have no message of his to read a language from, which is why every
prompt now names one. It is his chosen language (`students.language`, #172);
for a student who has not opened the app since that column arrived, the
language his goals are written in; and English after that
(`services/gemini/output_language.py` says why).
"""

import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from backend.core.language import Language
from backend.models.goal import Goal
from backend.repositories.student_repository import StudentRepository
from backend.services.gemini.output_language import output_language


async def student_language(
    session: AsyncSession, student_id: uuid.UUID, goals: list[Goal]
) -> Language:
    student = await StudentRepository(session).get_by_id(student_id)
    typed = [text for goal in goals for text in (goal.name or "", goal.description or "")]
    return output_language(student.language if student else None, *typed)
