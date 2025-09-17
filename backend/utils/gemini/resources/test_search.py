from backend.utils.gemini.resources.ebooks.search import search_ebooks
from backend.utils.gemini.resources.schema import ResourceSearchResults

goal_name = "Build a REST API in Python"
goal_description = "Build a full REST API in Python for analyzing data and statistics"
objective_name = "Learn programming logic"
objective_description = "Learn the basics of programming to write a simple script"
student_context = ["The student never executed a python script", "The student is a tech enthusiast", "The student is a CS freshman"]

ebooks : ResourceSearchResults = search_ebooks(goal_name, goal_description, objective_name, objective_description, student_context)

print(ebooks)