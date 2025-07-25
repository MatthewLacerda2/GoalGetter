 variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
  default     = "goal-getter"
}

variable "project_name" {
  description = "The name of the GCP project"
  type        = string
  default     = "GoalGetter"
}

variable "region" {
  description = "The GCP region to deploy resources"
  type        = string
  default     = "southamerica-west1"
}

variable "create_project" {
  description = "Whether to create a new GCP project"
  type        = bool
  default     = true
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
  default     = "MatthewLacerda2"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "GoalGetter"
}