from typing import List
from backend.services.gemini.resources.ebooks.search import search_ebooks
from backend.services.gemini.resources.websites.search import search_websites
from backend.services.gemini.resources.youtube.search import search_youtube_channels
from backend.services.gemini.resources.schema import ResourceSearchResults, ResourceSearchResultItem
#TODO: when you save the resources:
#- If the link ends with .pdf, its a book
#- If the link belongs to youtube, its youtube
#- Otherwise, its a website
def search_resources(
    goal_name: str, goal_description: str, objective_name: str, objective_description: str, student_context: list[str] | None
) -> ResourceSearchResults:
    
    ebooks : ResourceSearchResults = search_ebooks(goal_name, goal_description, objective_name, objective_description, student_context)
    websites : ResourceSearchResults = search_websites(goal_name, goal_description, objective_name, objective_description, student_context)
    youtube_channels : ResourceSearchResults = search_youtube_channels(goal_name, goal_description, objective_name, objective_description, student_context)
    
    all_resources : List[ResourceSearchResultItem] = ebooks.resources + youtube_channels.resources + websites.resources
    
    return ResourceSearchResults(resources=all_resources)