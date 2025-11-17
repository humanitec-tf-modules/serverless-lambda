output "function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.function.function_name
}

output "function_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.function.arn
}

output "function_url" {
  description = "The HTTPS URL endpoint for the Lambda function (if enable_function_url is true)"
  value       = var.enable_function_url ? aws_lambda_function_url.function_url[0].function_url : null
}

output "invoke_arn" {
  description = "The ARN to be used for invoking the Lambda function from API Gateway"
  value       = aws_lambda_function.function.invoke_arn
}

output "role_arn" {
  description = "The ARN of the IAM role used by the Lambda function"
  value       = var.iam_role_arn != null ? var.iam_role_arn : aws_iam_role.role[0].arn
}


output "humanitec_metadata" {
  description = "The Humanitec metadata annotations for the Lambda function"
  value = {
    Function-Arn    = aws_lambda_function.function.arn
    Function-Url    = var.enable_function_url ? aws_lambda_function_url.function_url[0].function_url : null
    Aws-Console-Url = "https://${local.aws_region}.console.aws.amazon.com/lambda/home?region=${local.aws_region}#/functions/${aws_lambda_function.function.function_name}"
  }
}
