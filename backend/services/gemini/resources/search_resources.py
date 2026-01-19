from backend.models.resource import Resource, StudyResourceType
from backend.utils.gemini.gemini_configs import get_gemini_embeddings
from backend.services.gemini.resources.schema import ResourceSearchResults
from backend.services.gemini.resources.ebooks.search import search_ebooks
from backend.services.gemini.resources.websites.search import search_websites
from backend.services.gemini.resources.youtube.search import search_youtube_channels

def search_resources(
    goal_id: str, goal_name: str, goal_description: str,
    objective_id: str, objective_name: str, objective_description: str,
    student_context: list[str] | None
) -> ResourceSearchResults:
    
    ebooks : ResourceSearchResults = search_ebooks(goal_name, goal_description, objective_name, objective_description, student_context)
    websites : ResourceSearchResults = search_websites(goal_name, goal_description, objective_name, objective_description, student_context)
    yt_channels : ResourceSearchResults = search_youtube_channels(goal_name, goal_description, objective_name, objective_description, student_context)
    
    ebook_resources= [Resource(
        goal_id= goal_id,
        objective_id= objective_id,
        resource_type= StudyResourceType.pdf,
        name= e.name,
        description= e.description,
        language= e.language,
        link= e.link,
        image_url= e.image_url,
        description_embedding = get_gemini_embeddings(e.description)
    )for e in ebooks.resources]
    
    site_resources= [Resource(
        goal_id= goal_id,
        objective_id= objective_id,
        resource_type= StudyResourceType.webpage,
        name= w.name,
        description= w.description,
        language= w.language,
        link= w.link,
        image_url= w.image_url,
        description_embedding = get_gemini_embeddings(w.description)
    )for w in websites.resources]
    
    yt_resources= [Resource(
        goal_id= goal_id,
        objective_id= objective_id,
        resource_type= StudyResourceType.youtube,
        name= y.name,
        description= y.description,
        language= y.language,
        link= y.link,
        image_url= y.image_url,
        description_embedding = get_gemini_embeddings(y.description)
    )for y in yt_channels.resources]
    
    response = ebook_resources + site_resources + yt_resources
    
    return response