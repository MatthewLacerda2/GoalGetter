from backend.utils.gemini.resources.ebooks.search import search_ebooks
from backend.utils.gemini.resources.schema import ResourceSearchResults

#You can call this test with
#python -m backend.utils.gemini.resources.test_ebooks

goal_name = "Learn to cook well"
goal_description = "Be profficient at cooking to do so independently"
objective_name = "Learn to cook fried chicken"
objective_description = "Learn to cook fried chicken for lunch"
student_context = ["The student never cooked anything", "The student will start living by himself"]

ebooks : ResourceSearchResults = search_ebooks(goal_name, goal_description, objective_name, objective_description, student_context)

print(ebooks)