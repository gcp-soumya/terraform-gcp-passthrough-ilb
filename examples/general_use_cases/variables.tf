# variables.tf in your root configuration
variable "gcp_project_id" {
  description = "Your Google Cloud Project ID."
  type        = string
}

variable "gcp_region" {
  description = "The GCP region to deploy resources in."
  type        = string
  default     = "us-central1"
}
