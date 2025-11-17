resource "random_id" "entropy" {
  byte_length = 4
  prefix      = var.name_prefix
}

resource "aws_lambda_function" "function" {
  function_name = random_id.entropy.hex
  role          = local.create_lambda_role ? aws_iam_role.role[0].arn : var.iam_role_arn

  package_type = "Zip"
  s3_bucket    = var.s3_bucket
  s3_key       = var.s3_key

  handler = var.handler
  runtime = var.runtime

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  architectures = var.architectures

  timeout     = var.timeout_in_seconds
  memory_size = var.memory_size

  tags = var.additional_tags
}

# Lambda Function URL - Creates an HTTPS endpoint for the Lambda
resource "aws_lambda_function_url" "function_url" {
  count = var.enable_function_url ? 1 : 0

  function_name      = aws_lambda_function.function.function_name
  authorization_type = var.function_url_auth_type

  dynamic "cors" {
    for_each = var.function_url_cors != null ? [var.function_url_cors] : []
    content {
      allow_credentials = cors.value.allow_credentials
      allow_origins     = cors.value.allow_origins
      allow_methods     = cors.value.allow_methods
      allow_headers     = cors.value.allow_headers
      expose_headers    = cors.value.expose_headers
      max_age           = cors.value.max_age
    }
  }
}
