# Configure the Google Cloud Provider
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
  region = "us-central1"
}

resource "google_project" "goal_getter_project" {
  name            = "Goal Getter"
  project_id      = "goal-getter-${random_id.project_suffix.hex}"
  billing_account = var.billing_account_id
  org_id          = var.org_id
}

# Generate a random suffix for the project ID to ensure uniqueness
resource "random_id" "project_suffix" {
  byte_length = 4
}

resource "google_project_service" "required_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "cloudbuild.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "containerregistry.googleapis.com"
  ])
  
  project = google_project.goal_getter_project.project_id
  service = each.value

  disable_dependent_services = true
  disable_on_destroy         = false
}

variable "billing_account_id" {
  description = "The ID of the billing account to associate with the project"
  type        = string
}

variable "org_id" {
  description = "The ID of the organization (optional)"
  type        = string
  default     = ""
}

output "project_id" {
  description = "The ID of the created project"
  value       = google_project.goal_getter_project.project_id
}

output "project_name" {
  description = "The name of the created project"
  value       = google_project.goal_getter_project.name
}
