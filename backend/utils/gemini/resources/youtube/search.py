import requests
from typing import List
from google.genai import types
from urllib.parse import urljoin, urlparse
from backend.utils.gemini.gemini_configs import get_client, get_gemini_config, get_gemini_config_plain_text
from backend.utils.gemini.resources.youtube.prompt import get_search_youtube_channels_prompt, get_search_youtube_channels_prompt_plain_text
from backend.utils.gemini.resources.schema import ResourceSearchResults, GeminiResourceSearchResults, ResourceSearchResultItem

def search_youtube_channels(
    goal_name: str, goal_description: str, objective_name: str, objective_description: str, student_context: list[str] | None
) -> ResourceSearchResults:
    print("Searching with Gemini...")
    gemini_results_plain_text : GeminiResourceSearchResults = gemini_search_youtube_channels_plain_text(goal_name, goal_description, objective_name, objective_description, student_context)
    gemini_results : GeminiResourceSearchResults = gemini_search_youtube_channels(gemini_results_plain_text)
    print("Gemini number of results:", len(gemini_results.resources))
    gemini_results = remove_duplicates(gemini_results)
    gemini_results = remove_invalid_links(gemini_results)
    print("Gemini number of results after removing invalid links:", len(gemini_results.resources))
    resources = add_links_to_results(gemini_results)
    print("Number of resources with links:", len(resources))
    return ResourceSearchResults(resources=resources)

def remove_duplicates(resources: GeminiResourceSearchResults) -> GeminiResourceSearchResults:
    resources_list = list(set(resources.resources))
    return GeminiResourceSearchResults(resources=resources_list)

def remove_invalid_links(resources: GeminiResourceSearchResults) -> GeminiResourceSearchResults:
    from urllib.parse import urlparse

    def is_valid_url(url: str) -> bool:
        try:
            result = urlparse(url)
            return all([result.scheme, result.netloc])
        except Exception:
            return False

    resources_list = [resource for resource in resources.resources if resource.link and is_valid_url(resource.link)]
    return GeminiResourceSearchResults(resources=resources_list)

def gemini_search_youtube_channels_plain_text(
    goal_name: str, goal_description: str, objective_name: str, objective_description: str, student_context: list[str] | None
) -> GeminiResourceSearchResults:
    
    grounding_tool = types.Tool(
        google_search=types.GoogleSearch()
    )
    
    client = get_client()
    model = "gemini-2.5-pro"
    full_prompt = get_search_youtube_channels_prompt_plain_text(goal_name, goal_description, objective_name, objective_description, student_context)
    config = get_gemini_config_plain_text()
    config.tools = [grounding_tool]
    
    response = client.models.generate_content(
        model=model, contents=full_prompt, config=config
    )
    print("Gemini results plain text:", response.text)
    return response.text

def gemini_search_youtube_channels(gemini_results_plain_text: str) -> GeminiResourceSearchResults:
    
    client = get_client()
    model = "gemini-2.5-pro"
    full_prompt = get_search_youtube_channels_prompt(gemini_results_plain_text)
    config = get_gemini_config(GeminiResourceSearchResults.model_json_schema())
    
    response = client.models.generate_content(
        model=model, contents=full_prompt, config=config
    )
    
    json_response = response.text
    
    return GeminiResourceSearchResults.model_validate_json(json_response)

def add_links_to_results(resources: GeminiResourceSearchResults) -> List[ResourceSearchResultItem]:        
    return [ResourceSearchResultItem(
        name=resource.name,
        description=resource.description,
        language=resource.language,
        link=resource.link,
        image_url=get_image_url(resource.link)
    ) for resource in resources.resources]

def get_image_url(link: str) -> str | None:
    try:
        parsed_url = urlparse(link)
        base_url = f"{parsed_url.scheme}://{parsed_url.netloc}"
        
        favicon_url = urljoin(base_url, "favicon.ico")
        
        response = requests.head(favicon_url, timeout=5)
        
        if response.status_code == 200:
            return favicon_url
        else:
            return None
            
    except Exception:
        return None