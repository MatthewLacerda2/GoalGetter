from backend.utils.gemini.resources.websites.search import search_websites
from backend.utils.gemini.resources.schema import ResourceSearchResults

#You can call this test with
#python -m backend.utils.gemini.resources.test_websites

goal_name = "Learn to cook well"
goal_description = "Be profficient at cooking to do so independently"
objective_name = "Learn to cook fried chicken"
objective_description = "Learn to cook fried chicken for lunch"
student_context = ["The student never cooked anything", "The student will start living by himself"]

websites : ResourceSearchResults = search_websites(goal_name, goal_description, objective_name, objective_description, student_context)

print(websites)