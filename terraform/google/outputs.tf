output "project_id" {
  value = google_project.goalgetter.project_id
}

output "project_number" {
  value = google_project.goalgetter.number
}

# The key strings are deliberately not outputs: .env on the deploy machine holds
# them, and the state (local, never committed) is the only other copy.
