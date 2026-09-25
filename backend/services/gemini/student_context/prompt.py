from backend.services.gemini.student_context.schema import GeminiStudentContext, StudentGoal


def format_goals(goals: list[StudentGoal]) -> str:
    """Every goal the student is studying, name and description. A context is
    written about the person, so the prompt sees all of them at once (#87)."""
    if not goals:
        return "The student has no goals yet."
    return "\n".join([f'- "{goal.name}": {goal.description}' for goal in goals])


def get_student_context_prompt(
    goals: list[StudentGoal],
    onboarding_prompt: str | None = None,
    questions_answers: list[tuple[str, str]] | None = None,
) -> str:
    context_parts = []

    if onboarding_prompt:
        context_parts.append(f"Initial goal request: {onboarding_prompt}")

    if questions_answers:
        qa_text = "\n".join([f"- {q}: {a}" for q, a in questions_answers])
        context_parts.append(f"Onboarding questions and answers:\n{qa_text}")

    context_section = (
        "\n\n".join(context_parts)
        if context_parts
        else "No additional onboarding context available."
    )

    return f"""
    ## Context
    You are an AI Tutor analyzing a new student's profile.

    The student is studying these goals:
    {format_goals(goals)}

    {context_section}

    ## Task
    Based on the information provided, generate an initial student context profile with two components:

    1. **State**: A concise description of the student's current knowledge level, experience, and position in their learning journey. This should capture what they know, what they don't know, and where they are starting from.

    2. **Metacognition**: A description of the student's awareness of their own learning process, their understanding of what they need to learn, their motivations, concerns, and learning approach. This captures their thinking about thinking.

    ## Format
    You will return a JSON object with:
    - state: A string (less than 100 words) describing the student's current state
    - metacognition: A string (less than 100 words) describing the student's metacognitive understanding

    Be specific and insightful.
    Write about the learner, not about any single goal: what they know and how they think travels with them across everything they study.
    If onboarding data is limited, infer reasonable assumptions based on the goals.
    """


def format_numbered_goals(goals: list[StudentGoal]) -> str:
    """Every goal numbered, with what he asked for and where we are taking him
    (#133). The number is the position in this list and nothing else - it is
    never an id, and it means nothing after this call returns.

    The day-one description stays in the prompt beside the frontier because it
    is what says the move is a move: "circuits" is why "robotics" is the next
    threshold and not a change of subject.
    """
    if not goals:
        return "The student has no goals yet."
    return "\n".join(
        [
            f'[{i}] "{goal.name}" - asked for on day one: {goal.description}'
            f"\n    current frontier: {goal.frontier or goal.description}"
            for i, goal in enumerate(goals)
        ]
    )


def format_numbered_contexts(contexts: list[GeminiStudentContext]) -> str:
    """The readings the app is standing behind, numbered so the model can point
    at one (#90). The number is the position in this list and nothing else - it
    is never an id, and it means nothing after this call returns."""
    if not contexts:
        return "No reading of this student has been written yet."
    return "\n".join(
        [
            f'[{i}] State: "{c.state}" - Metacognition: "{c.metacognition}"'
            for i, c in enumerate(contexts)
        ]
    )


def get_context_review_prompt(
    goals: list[StudentGoal],
    contexts: list[GeminiStudentContext],
    recent_answers: list[dict],
    recent_chat_history: list[dict],
) -> str:
    """Ask what went stale and what is missing, rather than for a rewrite (#90).

    Rewriting the whole reading every night paid a premium call to produce much
    the same paragraphs. Here the model reads what already stands and answers
    about it: which of these no longer hold, and what would you add. Saying
    "nothing" is explicitly allowed, and is the cheapest answer there is.
    """
    answers_formatted = (
        "\n".join(
            [
                f"- Question: {res.get('question')}\n  Selected: {res.get('selected_option')}\n  Is Correct: {res.get('is_correct')}\n  Time Spent: {res.get('time_spent')}s"
                for res in recent_answers
            ]
        )
        if recent_answers
        else "No recent answers."
    )

    chat_formatted = (
        "\n".join(
            [
                f"User: {msg.get('prompt')}\nTutor: {msg.get('tutor_response')}"
                for msg in recent_chat_history
            ]
        )
        if recent_chat_history
        else "No recent chat history."
    )

    return f"""
    <Context>
    You are an AI Tutor keeping the app's reading of one student up to date.

    The goals they are studying. Each goal carries what the student asked for
    on day one, which never changes, and its current frontier - the threshold
    we are teaching them at now. The numbers are only for this reply:
    {format_numbered_goals(goals)}

    What the app currently believes about this learner. Each reading is
    numbered; the numbers are only for this reply:
    {format_numbered_contexts(contexts)}

    Recent answers (their performance, across every goal):
    {answers_formatted}

    Recent Chat Tutor Messages (what they asked and how they reasoned):
    {chat_formatted}
    </Context>

    <Task>
    Decide which of the readings above no longer describe this student, write
    any reading that is now missing, and say whether any goal's frontier has
    been outgrown.
    </Task>

    <Guidelines>
    - `reviewed`: one entry per numbered reading above, with its index and
      is_outdated. A reading is outdated when the recent evidence contradicts
      it or has made it obsolete - not merely because it could be worded better.
    - `new_contexts`: readings to add, each with a State (what they know, their
      gaps) and a Metacognition (how they think, react and motivate themselves),
      under 100 words each.
    - **Both lists may be empty, and that is a perfectly good answer.** If the
      student is where the readings say they are, mark nothing outdated and add
      nothing. Do not invent change to have something to report.
    - Only add a reading when it says something the readings above do not.
    - Write about the learner, not about any single goal: one reading of the
      person, covering everything they study.
    - `frontiers`: the goals whose frontier the student has outgrown, each with
      the goal's index and the new definition. A goal has no finish line: once
      a student holds what the frontier names, the next frontier is what that
      knowledge is useful for and what they seem interested in - someone who
      has learned what circuits are is taken on to robotics, not stopped.
    - **A frontier move is a threshold, not a change of subject.** It must stay
      recognisable as the same goal seen further on. What the student asks the
      tutor is the strongest evidence of where to take them; the recent chat
      above is there for that.
    - **Leaving `frontiers` empty is the normal night**, and the right answer
      whenever the student is still working at the frontier they are on. Do not
      move a target to have something to report.
    - Write the response in the student's language.
    </Guidelines>
    """
