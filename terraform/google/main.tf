# Google Cloud for GoalGetter: the project, its billing link, the two APIs the
# backend calls and the key for each. Everything here was created by hand in the
# console first and is adopted with the import blocks in imports.tf (#108), so
# a plan must never propose to create or replace any of it. See ../README.md.

terraform {
  # The version `make tf` runs (TF_IMAGE in the root Makefile); moving one moves both.
  required_version = "~> 1.16.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.4"
    }
  }
}

provider "google" {
  # Credentials: GOOGLE_OAUTH_ACCESS_TOKEN, which `make tf` fills from the
  # active gcloud login. No service account key exists for this project.
  project = var.project_id
}

locals {
  # Only the APIs GoalGetter calls. The project also has a tail of services
  # Google enables on every new project (BigQuery, Cloud Storage, Logging, ...);
  # they are left unmanaged on purpose - ../README.md says why.
  used_services = toset([
    "generativelanguage.googleapis.com", # Gemini: every generated text and embedding
    "youtube.googleapis.com",            # YouTube Data API v3: the resource job
  ])
}

resource "google_project" "goalgetter" {
  name            = "GoalGetter AI Tutor"
  project_id      = var.project_id
  billing_account = var.billing_account

  # A deleted project id can never be used again, and the OAuth client lives in
  # this project. Both guards: the provider's, and Terraform's own.
  deletion_policy = "PREVENT"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_project_service" "used" {
  for_each = local.used_services

  project = google_project.goalgetter.project_id
  service = each.key

  # Removing a line above stops managing the API; it never turns it off.
  disable_on_destroy = false
}
