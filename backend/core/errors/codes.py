"""Every error a client of the API can receive, in one closed set (#214).

A member is one error: its value is the `code` the response carries, and it
declares the HTTP status it answers with and the English sentence that goes
in `detail` when the raiser has nothing more specific to say. The app switches
on the code, never on the sentence: `detail` is for a human reading a log or
Swagger, so rewording it breaks nothing.

The same set is mirrored in the app (`frontend/lib/core/api/error_code.dart`),
and the frontend's contract test holds the two equal through the OpenAPI
schema, where this enum appears as `ErrorCode`. Adding a member is adding it
there too, with the message a student reads for it.

Statuses are chosen for what the app does with them, not only for HTTP's sake:
a 401 signs the student out, so only a problem with *his* session is a 401. A
failure of a service we call (Google, Gemini) is ours, never his, and is a 5xx
of its own however that service answered us.
"""

from enum import StrEnum
from http import HTTPStatus


class ErrorCode(StrEnum):
    """The `code` of an error response. See the module docstring."""

    # Set per member by `__new__`, from the member's declaration.
    status: HTTPStatus
    sentence: str

    def __new__(cls, value: str, status: HTTPStatus, sentence: str) -> ErrorCode:
        member = str.__new__(cls, value)
        member._value_ = value
        member.status = status
        member.sentence = sentence
        return member

    # The request itself, as FastAPI and slowapi refuse it before any route runs.
    INVALID_REQUEST = "invalid_request", HTTPStatus.UNPROCESSABLE_CONTENT, "Invalid request"
    ROUTE_NOT_FOUND = "route_not_found", HTTPStatus.NOT_FOUND, "Not Found"
    METHOD_NOT_ALLOWED = "method_not_allowed", HTTPStatus.METHOD_NOT_ALLOWED, "Method Not Allowed"
    TOO_MANY_REQUESTS = "too_many_requests", HTTPStatus.TOO_MANY_REQUESTS, "Too many requests"
    INTERNAL_ERROR = "internal_error", HTTPStatus.INTERNAL_SERVER_ERROR, "Internal server error"

    # His session: every 401 the app can receive, and each one signs him out.
    NOT_SIGNED_IN = "not_signed_in", HTTPStatus.UNAUTHORIZED, "Not authenticated"
    INVALID_TOKEN = "invalid_token", HTTPStatus.UNAUTHORIZED, "Invalid token"
    STUDENT_NO_LONGER_EXISTS = (
        "student_no_longer_exists",
        HTTPStatus.UNAUTHORIZED,
        "Student no longer exists",
    )
    INVALID_REFRESH_TOKEN = (
        "invalid_refresh_token",
        HTTPStatus.UNAUTHORIZED,
        "Invalid or expired refresh token",
    )
    INVALID_GOOGLE_TOKEN = "invalid_google_token", HTTPStatus.UNAUTHORIZED, "Invalid Google token"
    STUDENT_NOT_FOUND = "student_not_found", HTTPStatus.NOT_FOUND, "User not found"

    # His goals, lessons and tutor chat.
    NO_ACTIVE_GOAL = "no_active_goal", HTTPStatus.NOT_FOUND, "No active goal"
    GOAL_NOT_FOUND = "goal_not_found", HTTPStatus.NOT_FOUND, "Goal not found"
    # `detail` is Gemini's reasoning, written in his language: the one detail
    # the app shows him as it is.
    NOT_A_GOAL = "not_a_goal", HTTPStatus.BAD_REQUEST, "The prompt is not a goal"
    LESSONS_NOT_READY = "lessons_not_ready", HTTPStatus.CONFLICT, "Lessons are still being prepared"
    UNKNOWN_QUESTION = (
        "unknown_question",
        HTTPStatus.UNPROCESSABLE_CONTENT,
        "An answer names a question outside this goal",
    )
    MESSAGE_NOT_FOUND = "message_not_found", HTTPStatus.NOT_FOUND, "Message not found"

    # A service we call failed. Ours to fix or wait out, never his session.
    GOOGLE_UNREACHABLE = (
        "google_unreachable",
        HTTPStatus.SERVICE_UNAVAILABLE,
        "Could not reach Google",
    )
    GEMINI_NO_ANSWER = "gemini_no_answer", HTTPStatus.BAD_GATEWAY, "Gemini gave no usable answer"
    # Gemini's 401/403: our API key, not his session (#214).
    GEMINI_KEY_REJECTED = (
        "gemini_key_rejected",
        HTTPStatus.BAD_GATEWAY,
        "Gemini refused our API key",
    )
    # Gemini's 429: our quota or credits, not his pace.
    GEMINI_QUOTA_EXHAUSTED = (
        "gemini_quota_exhausted",
        HTTPStatus.SERVICE_UNAVAILABLE,
        "Gemini's quota is used up",
    )
    GEMINI_FAILED = "gemini_failed", HTTPStatus.BAD_GATEWAY, "Gemini answered with an error"
    GEMINI_TIMED_OUT = (
        "gemini_timed_out",
        HTTPStatus.GATEWAY_TIMEOUT,
        "Gemini did not answer in time",
    )
    GEMINI_UNREACHABLE = "gemini_unreachable", HTTPStatus.GATEWAY_TIMEOUT, "Gemini is unreachable"
