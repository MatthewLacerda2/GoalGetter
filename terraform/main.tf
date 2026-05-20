terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  # Uses your local authenticated gcloud credentials automatically
}

resource "google_project" "goalgetter_project" {
  name            = "GoalGetter AI Tutor"
  project_id      = var.project_id
  billing_account = var.billing_account
}

resource "google_project_service" "generativelanguage" {
  project = google_project.goalgetter_project.project_id
  service = "generativelanguage.googleapis.com"

  disable_on_destroy = false
}
