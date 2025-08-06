data "aws_ssm_parameter" "database_uri" {
  name = "DATABASE_URI"
  with_decryption = false
}

resource "aws_ssm_parameter" "google_api_key" {
  name        = "GOOGLE_API_KEY"
  type        = "SecureString"
  value       = var.google_api_key
}

resource "aws_ssm_parameter" "google_auth_key" {
  name        = "GOOGLE_AUTH_KEY"
  type        = "SecureString"
  value       = var.google_auth_key
}

resource "aws_ssm_parameter" "backend_service_path" {
  name        = "BACKEND_SERVICE_PATH"
  type        = "String"  # Not SecureString since this is typically a URL
  value       = var.backend_service_path
}