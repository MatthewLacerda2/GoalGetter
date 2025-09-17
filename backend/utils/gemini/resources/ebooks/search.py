from typing import List
from google.genai import types
from backend.utils.gemini.gemini_configs import get_client, get_gemini_config
from backend.utils.gemini.resources.ebooks.prompt import get_search_ebooks_prompt
from backend.utils.gemini.resources.schema import ResourceSearchResults, GeminiResourceSearchResults, ResourceSearchResultItem
import requests
from urllib.parse import urljoin, urlparse

def search_ebooks(
    goal_name: str, goal_description: str, objective_name: str, objective_description: str, student_context: list[str] | None
) -> ResourceSearchResults:
    
    gemini_results : GeminiResourceSearchResults = gemini_search_ebooks(goal_name, goal_description, objective_name, objective_description, student_context)
    
    gemini_results = remove_duplicates(gemini_results)
    gemini_results = remove_non_pdf_links(gemini_results)    
    
    resources = results_with_links(gemini_results)
    
    return ResourceSearchResults(resources=resources)

def remove_duplicates(resources: List[GeminiResourceSearchResults]) -> List[GeminiResourceSearchResults]:
    return list(set(resources))

def remove_non_pdf_links(resources: List[GeminiResourceSearchResults]) -> List[GeminiResourceSearchResults]:
    return [resource for resource in resources if resource.link.endswith('.pdf')]

def gemini_search_ebooks(
    goal_name: str, goal_description: str, objective_name: str, objective_description: str, student_context: list[str] | None
) -> GeminiResourceSearchResults:
    
    grounding_tool = types.Tool(
        google_search=types.GoogleSearch()
    )
    
    client = get_client()
    model = "gemini-2.5-pro"
    full_prompt = get_search_ebooks_prompt(goal_name, goal_description, objective_name, objective_description, student_context)
    config = get_gemini_config(GeminiResourceSearchResults.model_json_schema())
    config.tools = [grounding_tool]
    
    response = client.models.generate_content(
        model=model, contents=full_prompt, config=config
    )
    
    json_response = response.text
    
    return GeminiResourceSearchResults.model_validate_json(json_response)

def results_with_links(resources: List[GeminiResourceSearchResults]) -> List[ResourceSearchResultItem]:        
    return [ResourceSearchResultItem(
        name=resource.name,
        description=resource.description,
        language=resource.language,
        link=resource.link,
        image_url=get_image_url(resource.link)
    ) for resource in resources]

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