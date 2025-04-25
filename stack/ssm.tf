data "aws_ssm_parameter" "database_uri" {
  name = "DATABASE_URI"
  with_decryption = false
}