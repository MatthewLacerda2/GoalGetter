from backend.services.gemini.resources.schema import ResourceSearchResults
from backend.services.gemini.resources.youtube.search import search_youtube_channels

#You can call this test with
#python -m backend.utils.gemini.resources.test_youtube

goal_name = "Learn to cook well"
goal_description = "Be profficient at cooking to do so independently"
objective_name = "Learn to cook fried chicken"
objective_description = "Learn to cook fried chicken for lunch"
student_context = ["The student never cooked anything", "The student will start living by himself"]

youtube_channels : ResourceSearchResults = search_youtube_channels(goal_name, goal_description, objective_name, objective_description, student_context)

print(youtube_channels)