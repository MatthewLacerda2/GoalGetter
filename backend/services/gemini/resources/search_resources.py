import logging

from google.genai import types

from backend.models.resource import Resource
from backend.services.gemini.resources.schema import GeminiResourceSearchResults
from backend.utils.envs import GEMINI_FAST_MODEL
from backend.utils.gemini.gemini_configs import (
    get_client,
    get_gemini_config,
    get_gemini_config_plain_text,
    get_gemini_embeddings,
)

logger = logging.getLogger(__name__)


def search_resources(
    goal_id: str,
    goal_name: str,
    goal_description: str,
    student_context: str | None = None,
    existing_links: list[str] | None = None,
) -> list[Resource]:
    """Nine resources for one goal, searched for this student.

    `student_context` is the app's reading of the learner - the chain never
    calls this without one ("no resources without memory", the user), and the
    parameter stays optional only so `make gemini resource-search` can be run
    against a goal alone. `existing_links` are the links the goal already
    holds, so a second run is asked for something new; the caller still dedupes
    what comes back, because asking is not obeying.
    """
    client = get_client()
    model = GEMINI_FAST_MODEL

    context_str = (
        f"Student's background and level: {student_context}" if student_context else "None"
    )
    held = (
        "The student already has these links. Do not recommend any of them again:\n"
        + "\n".join(f"- {link}" for link in existing_links)
        if existing_links
        else "The student has no resources for this goal yet."
    )

    prompt = f"""
    You are an expert tutor. Search for exactly:
    - 3 YouTube channels or videos that are highly relevant to learning "{goal_name}" (described as: "{goal_description}").
    - 3 Webpages or websites that teach "{goal_name}".
    - 3 PDF guides, eBooks, or PDF cheatsheets relevant to learning "{goal_name}".

    Take into account the student's level and context: "{context_str}".

    {held}

    You have the Google Search tool. Use it to find actual, existing, valid URLs for these resources.
    Format your response in plain text first, listing each resource's name, type, description, language, and exact URL link.
    """

    config = get_gemini_config_plain_text(tools=[types.Tool(google_search=types.GoogleSearch())])

    logger.info("Performing Google search grounding for resources...")
    search_response = client.models.generate_content(model=model, contents=prompt, config=config)

    format_prompt = f"""
    You are an assistant that formats search results into a clean JSON structure.
    Convert the following text containing recommendations into the requested JSON schema.
    Ensure all links are valid, exact URLs.

    Text:
    {search_response.text}
    """

    config_json = get_gemini_config(GeminiResourceSearchResults.model_json_schema())
    logger.info("Formatting resource results into JSON...")
    json_response = client.models.generate_content(
        model=model, contents=format_prompt, config=config_json
    )

    structured_results = GeminiResourceSearchResults.model_validate_json(json_response.text)

    resources = []
    for item in structured_results.resources:
        try:
            # Generate local description embeddings
            embedding = get_gemini_embeddings(item.description)
            resources.append(
                Resource(
                    goal_id=goal_id,
                    resource_type=item.resource_type,
                    name=item.name,
                    description=item.description,
                    language=item.language,
                    link=item.link,
                    description_embedding=embedding,
                )
            )
        except Exception as e:
            logger.error(f"Error processing resource recommendation: {e}")

    return resources
