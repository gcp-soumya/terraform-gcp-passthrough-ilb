# modules/gcp-passthrough-ilb/versions.tf
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0" # Ensure you use a recent version
    }
  }
}
