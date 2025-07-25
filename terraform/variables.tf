 variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
  default     = "goal-getter-12345" # Change this to your desired project ID
}

variable "project_name" {
  description = "The name of the GCP project"
  type        = string
  default     = "GoalGetter"
}

variable "region" {
  description = "The GCP region to deploy resources"
  type        = string
  default     = "us-central1"
}

variable "create_project" {
  description = "Whether to create a new GCP project"
  type        = bool
  default     = false # Set to true if you want to create a new project
}

variable "billing_account" {
  description = "The billing account ID (required if creating new project)"
  type        = string
  default     = ""
}

variable "org_id" {
  description = "The organization ID (optional, required if creating new project)"
  type        = string
  default     = ""
}

variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
  default     = "your-github-username" # Change this
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "GoalGetter" # Change this if different
}