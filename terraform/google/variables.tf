variable "project_id" {
  type        = string
  description = "The Google Cloud project id. It can never be reused once deleted."
  default     = "goalgetter-ai-tutor-1996"
}

variable "billing_account" {
  type        = string
  description = "The billing account the project is linked to."
  default     = "0118FD-436A50-6FFD59"
}
