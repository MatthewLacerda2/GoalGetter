from typing import List
from backend.utils.gemini.resources.schema import ResourceSearchResults, ResourceSearchResultItem
from backend.utils.gemini.resources.ebooks.search import search_ebooks

def search_resources(
    goal_name: str, goal_description: str, objective_name: str, objective_description: str, student_context: list[str] | None
) -> ResourceSearchResults:
    
    ebooks : ResourceSearchResults = search_ebooks(goal_name, goal_description, objective_name, objective_description, student_context)
    youtubers : ResourceSearchResults = search_youtubers(goal_name, goal_description, objective_name, objective_description, student_context)
    websites : ResourceSearchResults = search_websites(goal_name, goal_description, objective_name, objective_description, student_context)
    
    all_resources : List[ResourceSearchResultItem] = ebooks.resources + youtubers.resources + websites.resources
    
    return ResourceSearchResults(resources=all_resources)