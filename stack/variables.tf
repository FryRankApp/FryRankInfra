variable "google_api_key" {
  description = "Google API Key for Places API and Maps"
  type        = string
  sensitive   = true
}

variable "google_auth_key" {
  description = "Google Auth Client ID for OAuth"
  type        = string
  sensitive   = true
}

variable "backend_service_path" {
  description = "Backend service URL for the React app"
  type        = string
}