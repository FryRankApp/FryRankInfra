data "aws_ssm_parameter" "database_uri" {
  name            = "DATABASE_URI"
  with_decryption = false
}

data "aws_ssm_parameter" "google_api_key" {
  name            = "GOOGLE_API_KEY"
  with_decryption = true
}

data "aws_ssm_parameter" "google_auth_key" {
  name            = "GOOGLE_AUTH_KEY"
  with_decryption = true
}

data "aws_ssm_parameter" "backend_service_path" {
  name            = "BACKEND_SERVICE_PATH"
  with_decryption = false
}

resource "aws_ssm_parameter" "disable_auth" {
  name      = "DISABLE_AUTH"
  type      = "String"
  value     = "false"
  overwrite = false
}