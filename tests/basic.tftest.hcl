provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
}

run "test_basic_lambda" {
  command = plan

  variables {
    s3_bucket = "test-deployment-bucket"
    s3_key    = "test-function.zip"
    runtime   = "python3.12"
    handler   = "lambda_function.lambda_handler"
  }

  assert {
    condition     = aws_lambda_function.function.runtime == "python3.12"
    error_message = "Runtime should be python3.12"
  }

  assert {
    condition     = aws_lambda_function.function.handler == "lambda_function.lambda_handler"
    error_message = "Handler should match the provided value"
  }

  assert {
    condition     = aws_lambda_function.function.memory_size == 128
    error_message = "Default memory size should be 128"
  }

  assert {
    condition     = aws_lambda_function.function.timeout == 300
    error_message = "Default timeout should be 300"
  }

  assert {
    condition     = length(aws_iam_role.role) == 1
    error_message = "Should create IAM role when iam_role_arn is not provided"
  }
}

run "test_lambda_with_existing_role" {
  command = plan

  variables {
    s3_bucket    = "test-deployment-bucket"
    s3_key       = "test-function.zip"
    runtime      = "python3.12"
    handler      = "lambda_function.lambda_handler"
    iam_role_arn = "arn:aws:iam::123456789012:role/existing-lambda-role"
  }

  assert {
    condition     = length(aws_iam_role.role) == 0
    error_message = "Should not create IAM role when iam_role_arn is provided"
  }

  assert {
    condition     = aws_lambda_function.function.role == "arn:aws:iam::123456789012:role/existing-lambda-role"
    error_message = "Should use the provided IAM role ARN"
  }
}

run "test_lambda_with_custom_config" {
  command = plan

  variables {
    s3_bucket          = "test-deployment-bucket"
    s3_key             = "test-function.zip"
    runtime            = "nodejs20.x"
    handler            = "index.handler"
    timeout_in_seconds = 60
    memory_size        = 512
    architectures      = ["arm64"]
  }

  assert {
    condition     = aws_lambda_function.function.timeout == 60
    error_message = "Timeout should be 60 seconds"
  }

  assert {
    condition     = aws_lambda_function.function.memory_size == 512
    error_message = "Memory size should be 512 MB"
  }

  assert {
    condition     = length(aws_lambda_function.function.architectures) == 1 && aws_lambda_function.function.architectures[0] == "arm64"
    error_message = "Architecture should be arm64"
  }
}

run "test_lambda_with_environment_variables" {
  command = plan

  variables {
    s3_bucket = "test-deployment-bucket"
    s3_key    = "test-function.zip"
    runtime   = "python3.12"
    handler   = "lambda_function.lambda_handler"

    environment_variables = {
      ENVIRONMENT = "test"
      LOG_LEVEL   = "debug"
      API_KEY     = "test-key"
    }
  }

  assert {
    condition     = aws_lambda_function.function.environment[0].variables["ENVIRONMENT"] == "test"
    error_message = "Environment variable ENVIRONMENT should be 'test'"
  }

  assert {
    condition     = aws_lambda_function.function.environment[0].variables["LOG_LEVEL"] == "debug"
    error_message = "Environment variable LOG_LEVEL should be 'debug'"
  }

  assert {
    condition     = aws_lambda_function.function.environment[0].variables["API_KEY"] == "test-key"
    error_message = "Environment variable API_KEY should be 'test-key'"
  }
}

run "test_lambda_with_tags" {
  command = plan

  variables {
    s3_bucket = "test-deployment-bucket"
    s3_key    = "test-function.zip"
    runtime   = "python3.12"
    handler   = "lambda_function.lambda_handler"

    additional_tags = {
      project     = "test-project"
      environment = "development"
      team        = "platform"
    }
  }

  assert {
    condition     = aws_lambda_function.function.tags["project"] == "test-project"
    error_message = "Tag 'project' should be 'test-project'"
  }

  assert {
    condition     = aws_lambda_function.function.tags["environment"] == "development"
    error_message = "Tag 'environment' should be 'development'"
  }

  assert {
    condition     = aws_lambda_function.function.tags["team"] == "platform"
    error_message = "Tag 'team' should be 'platform'"
  }
}

run "test_lambda_with_inline_policies" {
  command = plan

  variables {
    s3_bucket = "test-deployment-bucket"
    s3_key    = "test-function.zip"
    runtime   = "python3.12"
    handler   = "lambda_function.lambda_handler"

    additional_inline_policies = {
      s3_access = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"s3:GetObject\",\"s3:PutObject\"],\"Resource\":\"arn:aws:s3:::my-bucket/*\"}]}"
    }
  }

  assert {
    condition     = length(aws_iam_role_policy.lambda_additional_inline_policies) == 1
    error_message = "Should create one inline policy"
  }

  assert {
    condition     = length(aws_iam_role.role) == 1
    error_message = "Should create IAM role when using inline policies"
  }
}

run "test_lambda_with_managed_policies" {
  command = plan

  variables {
    s3_bucket = "test-deployment-bucket"
    s3_key    = "test-function.zip"
    runtime   = "python3.12"
    handler   = "lambda_function.lambda_handler"

    additional_managed_policy_arns = [
      "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
      "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
    ]
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.lambda_additional_managed_policies) == 2
    error_message = "Should attach two managed policies"
  }

  assert {
    condition     = length(aws_iam_role.role) == 1
    error_message = "Should create IAM role when using managed policies"
  }
}

run "test_lambda_with_both_policy_types" {
  command = plan

  variables {
    s3_bucket = "test-deployment-bucket"
    s3_key    = "test-function.zip"
    runtime   = "python3.12"
    handler   = "lambda_function.lambda_handler"

    additional_managed_policy_arns = [
      "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess"
    ]

    additional_inline_policies = {
      sqs_access = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"sqs:SendMessage\"],\"Resource\":\"arn:aws:sqs:us-east-1:123456789012:my-queue\"}]}"
    }
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.lambda_additional_managed_policies) == 1
    error_message = "Should attach one managed policy"
  }

  assert {
    condition     = length(aws_iam_role_policy.lambda_additional_inline_policies) == 1
    error_message = "Should create one inline policy"
  }
}

run "test_lambda_with_function_url_iam_auth" {
  command = plan

  variables {
    s3_bucket              = "test-deployment-bucket"
    s3_key                 = "test-function.zip"
    runtime                = "python3.12"
    handler                = "lambda_function.lambda_handler"
    enable_function_url    = true
    function_url_auth_type = "AWS_IAM"
  }

  assert {
    condition     = length(aws_lambda_function_url.function_url) == 1
    error_message = "Should create Function URL when enable_function_url is true"
  }

  assert {
    condition     = aws_lambda_function_url.function_url[0].authorization_type == "AWS_IAM"
    error_message = "Function URL auth type should be AWS_IAM"
  }
}

run "test_lambda_with_function_url_no_auth" {
  command = plan

  variables {
    s3_bucket              = "test-deployment-bucket"
    s3_key                 = "test-function.zip"
    runtime                = "nodejs20.x"
    handler                = "index.handler"
    enable_function_url    = true
    function_url_auth_type = "NONE"
  }

  assert {
    condition     = length(aws_lambda_function_url.function_url) == 1
    error_message = "Should create Function URL when enable_function_url is true"
  }

  assert {
    condition     = aws_lambda_function_url.function_url[0].authorization_type == "NONE"
    error_message = "Function URL auth type should be NONE"
  }
}

run "test_lambda_without_function_url" {
  command = plan

  variables {
    s3_bucket           = "test-deployment-bucket"
    s3_key              = "test-function.zip"
    runtime             = "python3.12"
    handler             = "lambda_function.lambda_handler"
    enable_function_url = false
  }

  assert {
    condition     = length(aws_lambda_function_url.function_url) == 0
    error_message = "Should not create Function URL when enable_function_url is false"
  }

  assert {
    condition     = output.function_url == null
    error_message = "Function URL output should be null when function URL is not enabled"
  }
}

run "test_lambda_with_function_url_cors" {
  command = plan

  variables {
    s3_bucket              = "test-deployment-bucket"
    s3_key                 = "test-function.zip"
    runtime                = "nodejs20.x"
    handler                = "index.handler"
    enable_function_url    = true
    function_url_auth_type = "NONE"

    function_url_cors = {
      allow_origins     = ["https://example.com"]
      allow_methods     = ["GET", "POST"]
      allow_headers     = ["content-type"]
      expose_headers    = ["x-request-id"]
      allow_credentials = true
      max_age           = 3600
    }
  }

  assert {
    condition     = length(aws_lambda_function_url.function_url) == 1
    error_message = "Should create Function URL with CORS"
  }

  assert {
    condition     = length(aws_lambda_function_url.function_url[0].cors) == 1
    error_message = "Should configure CORS on Function URL"
  }
}

run "test_lambda_go_runtime" {
  command = plan

  variables {
    s3_bucket     = "test-deployment-bucket"
    s3_key        = "bootstrap.zip"
    runtime       = "provided.al2023"
    handler       = "bootstrap"
    architectures = ["x86_64"]
  }

  assert {
    condition     = aws_lambda_function.function.runtime == "provided.al2023"
    error_message = "Runtime should be provided.al2023 for Go"
  }

  assert {
    condition     = aws_lambda_function.function.handler == "bootstrap"
    error_message = "Handler should be bootstrap for Go"
  }
}

run "test_lambda_java_runtime" {
  command = plan

  variables {
    s3_bucket = "test-deployment-bucket"
    s3_key    = "java-function.zip"
    runtime   = "java21"
    handler   = "com.example.Handler::handleRequest"
  }

  assert {
    condition     = aws_lambda_function.function.runtime == "java21"
    error_message = "Runtime should be java21"
  }
}

run "test_lambda_custom_name_prefix" {
  command = plan

  variables {
    s3_bucket   = "test-deployment-bucket"
    s3_key      = "test-function.zip"
    runtime     = "python3.12"
    handler     = "lambda_function.lambda_handler"
    name_prefix = "custom-prefix-"
  }

  # Note: We can't assert on the exact function name due to random suffix,
  # but we can validate that the function is created
  assert {
    condition     = aws_lambda_function.function.runtime == "python3.12"
    error_message = "Function should be created with custom prefix"
  }
}

run "test_lambda_custom_iam_role_name_prefix" {
  command = plan

  variables {
    s3_bucket            = "test-deployment-bucket"
    s3_key               = "test-function.zip"
    runtime              = "python3.12"
    handler              = "lambda_function.lambda_handler"
    iam_role_name_prefix = "custom-role-prefix-"
  }

  assert {
    condition     = length(aws_iam_role.role) == 1
    error_message = "Should create IAM role"
  }

  assert {
    condition     = aws_iam_role.role[0].name_prefix == "custom-role-prefix-"
    error_message = "IAM role should use custom name prefix"
  }
}

run "test_outputs" {
  command = plan

  variables {
    s3_bucket = "test-deployment-bucket"
    s3_key    = "test-function.zip"
    runtime   = "python3.12"
    handler   = "lambda_function.lambda_handler"
  }

  # Note: In plan mode, output values that depend on computed resources (like random_id)
  # are not available. We validate the resources are created correctly instead.
  assert {
    condition     = aws_lambda_function.function.runtime == "python3.12"
    error_message = "Lambda function should be created"
  }

  assert {
    condition     = aws_lambda_function.function.handler == "lambda_function.lambda_handler"
    error_message = "Lambda function handler should be set correctly"
  }

  assert {
    condition     = length(aws_iam_role.role) == 1
    error_message = "IAM role should be created for outputs"
  }
}

run "test_s3_access_policy" {
  command = plan

  variables {
    s3_bucket = "test-deployment-bucket"
    s3_key    = "test-function.zip"
    runtime   = "python3.12"
    handler   = "lambda_function.lambda_handler"
  }

  assert {
    condition     = length(aws_iam_role_policy.s3_zip_bucket_access) == 1
    error_message = "Should create S3 access policy for deployment package"
  }
}

run "test_lambda_basic_execution_role" {
  command = plan

  variables {
    s3_bucket = "test-deployment-bucket"
    s3_key    = "test-function.zip"
    runtime   = "python3.12"
    handler   = "lambda_function.lambda_handler"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.lambda_basic.policy_arn == "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
    error_message = "Should attach AWSLambdaBasicExecutionRole"
  }
}

run "test_package_type" {
  command = plan

  variables {
    s3_bucket = "test-deployment-bucket"
    s3_key    = "test-function.zip"
    runtime   = "python3.12"
    handler   = "lambda_function.lambda_handler"
  }

  assert {
    condition     = aws_lambda_function.function.package_type == "Zip"
    error_message = "Package type should be Zip"
  }

  assert {
    condition     = aws_lambda_function.function.s3_bucket == "test-deployment-bucket"
    error_message = "S3 bucket should match the provided value"
  }

  assert {
    condition     = aws_lambda_function.function.s3_key == "test-function.zip"
    error_message = "S3 key should match the provided value"
  }
}
