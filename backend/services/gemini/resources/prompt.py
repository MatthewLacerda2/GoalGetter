"""The two prompts of the resource search (#175): a grounded search, then a
description of what it found. Both are English and name the student's language
outright (CLAUDE.md), and both ask for the shortest answer that does the job.
"""


def search_prompt(
    goal_name: str, goal_description: str, context: str, held: list[str], language: str
) -> str:
    held_line = (
        "He already has these; find others:\n" + "\n".join(f"- {link}" for link in held)
        if held
        else ""
    )
    return f"""
    Use Google Search to find study material for a student learning "{goal_name}"
    ({goal_description}). What the app knows about him: {context}
    {held_line}

    Find 3 web pages and 3 PDF guides, written in {language} where possible, that
    suit his level. No videos.

    Answer with one line per resource: its name and what it teaches, in {language}.
    Nothing else: no URLs, no introduction, no closing remarks.
    """


def describe_prompt(goal_name: str, context: str, sources: str, language: str) -> str:
    return f"""
    A Google search for study material on "{goal_name}" found the numbered sources
    below. Each shows its site and what the search said about it.
    What the app knows about the student: {context}

    {sources}

    Pick up to 3 web pages and 3 PDFs worth his time; skip the rest. For each,
    give its source number, whether it is a webpage or a pdf, a name of a few words
    and what it teaches in 20 words at most - both written in {language} - and the
    two-letter code of the language the page is written in.

    Also write one YouTube search query, in {language}, for videos that would suit him.
    Return only the JSON.
    """
