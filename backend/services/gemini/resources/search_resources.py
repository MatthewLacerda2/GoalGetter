import logging
from google.genai import types
from backend.models.resource import Resource
from backend.utils.gemini.gemini_configs import get_client, get_gemini_config, get_gemini_embeddings, get_gemini_config_plain_text
from backend.utils.envs import GEMINI_PREMIUM_MODEL
from backend.services.gemini.resources.schema import GeminiResourceSearchResults

logger = logging.getLogger(__name__)

def search_resources(
    goal_id: str,
    goal_name: str,
    goal_description: str,
    student_context: str | None = None
) -> list[Resource]:
    client = get_client()
    model = GEMINI_PREMIUM_MODEL
    
    context_str = f"Student's background and level: {student_context}" if student_context else "None"
    
    prompt = f"""
    You are an expert tutor. Search for exactly:
    - 3 YouTube channels or videos that are highly relevant to learning "{goal_name}" (described as: "{goal_description}").
    - 3 Webpages or websites that teach "{goal_name}".
    - 3 PDF guides, eBooks, or PDF cheatsheets relevant to learning "{goal_name}".
    
    Take into account the student's level and context: "{context_str}".
    
    You have the Google Search tool. Use it to find actual, existing, valid URLs for these resources.
    Format your response in plain text first, listing each resource's name, type, description, language, and exact URL link.
    """
    
    config = get_gemini_config_plain_text()
    config.tools = [types.Tool(google_search=types.GoogleSearch())]
    
    logger.info("Performing Google search grounding for resources...")
    search_response = client.models.generate_content(
        model=model, contents=prompt, config=config
    )
    
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
                    description_embedding=embedding
                )
            )
        except Exception as e:
            logger.error(f"Error processing resource recommendation: {e}")
            
    return resources