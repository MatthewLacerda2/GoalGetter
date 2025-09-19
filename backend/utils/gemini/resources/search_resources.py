from typing import List
from backend.utils.gemini.resources.schema import ResourceSearchResults, ResourceSearchResultItem
from backend.utils.gemini.resources.ebooks.search import search_ebooks
from backend.utils.gemini.resources.websites.search import search_websites
from backend.utils.gemini.resources.youtube.search import search_youtube_channels
#TODO: this is not being used
def search_resources(
    goal_name: str, goal_description: str, objective_name: str, objective_description: str, student_context: list[str] | None
) -> ResourceSearchResults:
    
    ebooks : ResourceSearchResults = search_ebooks(goal_name, goal_description, objective_name, objective_description, student_context)
    websites : ResourceSearchResults = search_websites(goal_name, goal_description, objective_name, objective_description, student_context)
    youtube_channels : ResourceSearchResults = search_youtube_channels(goal_name, goal_description, objective_name, objective_description, student_context)
    #TODO: add the resourcetype
    all_resources : List[ResourceSearchResultItem] = ebooks.resources + youtube_channels.resources + websites.resources
    
    return ResourceSearchResults(resources=all_resources)