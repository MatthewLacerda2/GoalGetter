from fastapi import HTTPException

from backend.core.errors.codes import ErrorCode


class ApiError(HTTPException):
    """Raise one of the API's errors: `raise ApiError(ErrorCode.NO_ACTIVE_GOAL)`.

    One class for every code rather than a class per code: the code already
    names the error and carries its status, so a class each would repeat the
    enum. `detail` replaces the code's default sentence when the raiser knows
    more (Gemini's reasoning, which question was unknown); it is for humans
    and logs, and the app never compares it.

    An `HTTPException`, so FastAPI's dependencies and anything that catches one
    treat it as it did before; `handlers.py` writes its body.
    """

    def __init__(
        self,
        code: ErrorCode,
        detail: str | None = None,
        headers: dict[str, str] | None = None,
    ) -> None:
        super().__init__(status_code=code.status, detail=detail or code.sentence, headers=headers)
        self.code = code
