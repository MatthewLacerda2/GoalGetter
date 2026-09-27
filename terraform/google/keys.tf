# The two API keys the backend reads from .env (GEMINI_API_KEY, YOUTUBE_API_KEY).
# Each is restricted to the one API it exists for, so a leaked key cannot be
# spent on anything else in the project.
#
# `name` is the key's id in Google, not a secret. The key string itself is only
# in the state (`key_string`, marked sensitive) and in .env - never in a .tf file.

resource "google_apikeys_key" "gemini" {
  project      = google_project.goalgetter.project_id
  name         = "f65894fd-2e8f-4ef2-a82d-982bc54c81fd"
  display_name = "GoalGetter Gemini Key"

  restrictions {
    api_targets {
      service = google_project_service.used["generativelanguage.googleapis.com"].service
    }
  }

  # A new key means a new string in .env on the deploy machine.
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_apikeys_key" "youtube" {
  project      = google_project.goalgetter.project_id
  name         = "9a116654-57e6-4c70-adf0-bef6e604cda1"
  display_name = "GoalGetter YouTube Key"

  restrictions {
    api_targets {
      service = google_project_service.used["youtube.googleapis.com"].service
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
