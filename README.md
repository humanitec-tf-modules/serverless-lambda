# AWS Lambda Module

A reusable Terraform module for deploying AWS Lambda functions with flexible IAM configuration and optional Function URLs.

## Overview

This module provides a streamlined way to deploy AWS Lambda functions with the following features:

- Lambda function deployment from S3-stored packages
- Automatic or custom IAM role management
- Support for additional managed and inline IAM policies
- Optional Lambda Function URLs with configurable authentication
- Configurable CORS for Function URLs
- Support for multiple runtimes (Python, Node.js, Go, Java, etc.)
- Customizable timeout, memory, and architecture settings
- Environment variable configuration
- Tagging support

## Prerequisites

Before using this module, ensure you have:

1. **An S3 bucket** containing your Lambda deployment package (ZIP file)
2. **AWS credentials** configured with appropriate permissions to create Lambda functions and IAM roles
3. **Lambda deployment package** uploaded to S3 in ZIP format

## Usage

### Basic Usage

Minimal configuration with automatic IAM role creation:

```hcl
module "simple_lambda" {
  source = "github.com/humanitec-tf-modules/serverless-lambda?ref=vX.Y.Z"

  s3_bucket = "my-deployment-bucket"
  s3_key    = "my-function.zip"
  runtime   = "python3.12"
  handler   = "lambda_function.lambda_handler"
}
```

### Lambda with Custom Configuration

```hcl
module "custom_lambda" {
  source = "github.com/humanitec-tf-modules/serverless-lambda?ref=vX.Y.Z"

  s3_bucket = "my-deployment-bucket"
  s3_key    = "my-function.zip"
  runtime   = "python3.12"
  handler   = "lambda_function.lambda_handler"

  timeout_in_seconds = 300
  memory_size        = 512
  architectures      = ["arm64"]

  environment_variables = {
    ENVIRONMENT = "production"
    LOG_LEVEL   = "info"
    API_KEY     = "your-api-key"
  }

  additional_tags = {
    project     = "my-project"
    environment = "production"
    managed_by  = "terraform"
  }
}
```

### Lambda with Function URL (Public Access)

This example creates a Lambda with a publicly accessible HTTPS endpoint:

```hcl
module "public_lambda" {
  source = "github.com/humanitec-tf-modules/serverless-lambda?ref=vX.Y.Z"

  s3_bucket = "my-deployment-bucket"
  s3_key    = "api-handler.zip"
  runtime   = "nodejs20.x"
  handler   = "index.handler"

  # Enable Function URL with public access
  enable_function_url      = true
  function_url_auth_type   = "NONE"

  # Configure CORS for web applications
  function_url_cors = {
    allow_origins     = ["https://example.com", "https://app.example.com"]
    allow_methods     = ["GET", "POST", "PUT", "DELETE"]
    allow_headers     = ["content-type", "x-custom-header"]
    expose_headers    = ["x-request-id"]
    allow_credentials = true
    max_age           = 86400
  }
}

output "api_url" {
  value = module.public_lambda.function_url
}
```

### Lambda with Function URL (IAM Authentication)

This example creates a Lambda with Function URL requiring AWS IAM authentication:

```hcl
module "secure_lambda" {
  source = "github.com/humanitec-tf-modules/serverless-lambda?ref=vX.Y.Z"

  s3_bucket = "my-deployment-bucket"
  s3_key    = "secure-api.zip"
  runtime   = "python3.12"
  handler   = "app.handler"

  # Enable Function URL with IAM authentication
  enable_function_url    = true
  function_url_auth_type = "AWS_IAM"
}
```

### Lambda with Inline IAM Policies

Use inline policies for Lambda-specific permissions:

```hcl
module "lambda_with_s3" {
  source = "github.com/humanitec-tf-modules/serverless-lambda?ref=vX.Y.Z"

  s3_bucket = "my-deployment-bucket"
  s3_key    = "s3-processor.zip"
  runtime   = "python3.12"
  handler   = "lambda_function.lambda_handler"

  additional_inline_policies = {
    s3_access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject"
          ]
          Resource = "arn:aws:s3:::my-data-bucket/*"
        }
      ]
    })

    dynamodb_access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:Query"
          ]
          Resource = "arn:aws:dynamodb:us-east-1:123456789012:table/MyTable"
        }
      ]
    })
  }
}
```

### Lambda with Managed IAM Policies

Attach AWS-managed or customer-managed policies:

```hcl
module "lambda_with_managed_policies" {
  source = "github.com/humanitec-tf-modules/serverless-lambda?ref=vX.Y.Z"

  s3_bucket = "my-deployment-bucket"
  s3_key    = "processor.zip"
  runtime   = "nodejs20.x"
  handler   = "index.handler"

  additional_managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  ]
}
```

### Lambda with Existing IAM Role

If you already have an IAM role configured:

```hcl
module "lambda_with_existing_role" {
  source = "github.com/humanitec-tf-modules/serverless-lambda?ref=vX.Y.Z"

  s3_bucket = "my-deployment-bucket"
  s3_key    = "my-function.zip"
  runtime   = "python3.12"
  handler   = "lambda_function.lambda_handler"

  # Use existing IAM role
  iam_role_arn = "arn:aws:iam::123456789012:role/my-existing-lambda-role"

  # Note: additional_managed_policy_arns and additional_inline_policies
  # will be IGNORED when iam_role_arn is provided
}
```

### Go Lambda with Custom Runtime

Example for Go Lambda functions using custom runtime:

```hcl
module "go_lambda" {
  source = "github.com/humanitec-tf-modules/serverless-lambda?ref=vX.Y.Z"

  s3_bucket = "my-deployment-bucket"
  s3_key    = "bootstrap.zip"

  # Go uses custom runtime
  runtime = "provided.al2023"
  handler = "bootstrap"

  architectures = ["x86_64"]

  timeout_in_seconds = 100
  memory_size        = 512

  environment_variables = {
    ENVIRONMENT = "production"
  }
}
```

### Complete Example with All Features

```hcl
module "full_featured_lambda" {
  source = "github.com/humanitec-tf-modules/serverless-lambda?ref=vX.Y.Z"

  # Lambda package configuration
  s3_bucket = "my-deployment-bucket"
  s3_key    = "comprehensive-function.zip"
  runtime   = "python3.12"
  handler   = "app.lambda_handler"

  # Function configuration
  timeout_in_seconds = 300
  memory_size        = 1024
  architectures      = ["arm64"]

  # Environment variables
  environment_variables = {
    ENVIRONMENT   = "production"
    LOG_LEVEL     = "info"
    DATABASE_URL  = "postgresql://..."
    CACHE_ENABLED = "true"
  }

  # Function URL configuration
  enable_function_url    = true
  function_url_auth_type = "NONE"

  function_url_cors = {
    allow_origins     = ["https://app.example.com"]
    allow_methods     = ["GET", "POST"]
    allow_headers     = ["content-type"]
    allow_credentials = false
    max_age           = 3600
  }

  # IAM policy configuration
  additional_managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess"
  ]

  additional_inline_policies = {
    s3_access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject"
          ]
          Resource = "arn:aws:s3:::my-bucket/*"
        }
      ]
    })

    sqs_access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "sqs:SendMessage",
            "sqs:ReceiveMessage",
            "sqs:DeleteMessage"
          ]
          Resource = "arn:aws:sqs:us-west-2:123456789012:my-queue"
        }
      ]
    })
  }

  # Tags
  additional_tags = {
    project     = "my-project"
    environment = "production"
    team        = "platform"
    cost_center = "engineering"
  }

  # Naming
  name_prefix = "my-company-"
}

# Outputs
output "function_name" {
  value = module.full_featured_lambda.function_name
}

output "function_arn" {
  value = module.full_featured_lambda.function_arn
}

output "function_url" {
  value = module.full_featured_lambda.function_url
}

output "role_arn" {
  value = module.full_featured_lambda.role_arn
}
```

## IAM Permissions

### Default Permissions

When the module creates an IAM role (when `iam_role_arn` is `null`), it automatically attaches:

1. **AWSLambdaBasicExecutionRole** - Allows Lambda to write logs to CloudWatch Logs
2. **S3 Access Policy** - Allows Lambda to read the deployment package from the specified S3 bucket

### Additional Permissions

You can add additional permissions using:

- **`additional_managed_policy_arns`**: For AWS-managed or customer-managed policies
- **`additional_inline_policies`**: For function-specific permissions

**Note**: Additional policies are ONLY applied when the module creates the IAM role. If you provide your own `iam_role_arn`, you must manage all permissions yourself.

## Lambda Function URLs

Lambda Function URLs provide a dedicated HTTP(S) endpoint for your Lambda function without requiring API Gateway. This is useful for:

- Simple HTTP APIs
- Webhooks
- Public endpoints
- Microservices

### Authentication Options

- **`NONE`**: Public access, no authentication required
- **`AWS_IAM`**: Requires AWS SigV4 authentication

### CORS Configuration

When using Function URLs with web applications, configure CORS:

```hcl
function_url_cors = {
  allow_credentials = true                              # Allow cookies/auth headers
  allow_origins     = ["https://app.example.com"]       # Allowed origins
  allow_methods     = ["GET", "POST", "PUT"]            # Allowed HTTP methods
  allow_headers     = ["content-type", "authorization"] # Allowed headers
  expose_headers    = ["x-request-id"]                  # Headers exposed to browser
  max_age           = 86400                             # Cache preflight for 24h
}
```

## Invoking Lambda Functions

After deploying your Lambda function, you can invoke it in several ways:

### 1. AWS CLI - Synchronous Invocation

Invoke the function and wait for the response:

```bash
# Get the function name from Terraform output
FUNCTION_NAME=$(terraform output -raw function_name)

# Invoke with a simple payload
aws lambda invoke \
  --function-name "$FUNCTION_NAME" \
  --payload '{"key": "value"}' \
  --region us-east-1 \
  response.json

# View the response
cat response.json
```

### 2. AWS CLI - Asynchronous Invocation

Invoke the function without waiting for the response:

```bash
aws lambda invoke \
  --function-name "$FUNCTION_NAME" \
  --invocation-type Event \
  --payload '{"key": "value"}' \
  --region us-east-1 \
  response.json
```

### 3. Function URL - HTTP Request (Public)

For Lambda functions with Function URLs and `auth_type = "NONE"`:

```bash
# Get the Function URL from Terraform output
FUNCTION_URL=$(terraform output -raw function_url)

# Simple GET request
curl "$FUNCTION_URL"

# POST request with JSON payload
curl -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d '{"key": "value", "message": "Hello Lambda"}'

# POST with additional headers
curl -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -H "X-Custom-Header: custom-value" \
  -d '{"action": "process", "data": {"id": 123}}'
```

### 4. Function URL - HTTP Request (IAM Authenticated)

For Function URLs with `auth_type = "AWS_IAM"`, you need to sign the request:

```bash
# Using awscurl (install with: pip install awscurl or brew install awscurl)
awscurl --service lambda \
  -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'

# Or using aws-sigv4-proxy
# https://github.com/awslabs/aws-sigv4-proxy
```

### 5. Python (boto3) Invocation

```python
import boto3
import json

# Create Lambda client
lambda_client = boto3.client('lambda', region_name='us-east-1')

# Prepare payload
payload = {
    "key": "value",
    "message": "Hello from Python"
}

# Synchronous invocation
response = lambda_client.invoke(
    FunctionName='your-function-name',
    InvocationType='RequestResponse',
    Payload=json.dumps(payload)
)

# Read response
result = json.loads(response['Payload'].read())
print(f"Status Code: {response['StatusCode']}")
print(f"Response: {result}")

# Asynchronous invocation
async_response = lambda_client.invoke(
    FunctionName='your-function-name',
    InvocationType='Event',
    Payload=json.dumps(payload)
)
print(f"Async Status Code: {async_response['StatusCode']}")
```

### 6. Python - HTTP Request to Function URL

```python
import requests
import json

# For public Function URLs (auth_type = "NONE")
function_url = "https://abcdefg.lambda-url.us-east-1.on.aws/"

payload = {
    "action": "process",
    "data": {"id": 123, "name": "example"}
}

response = requests.post(
    function_url,
    json=payload,
    headers={"Content-Type": "application/json"}
)

print(f"Status Code: {response.status_code}")
print(f"Response: {response.json()}")

# For IAM-authenticated Function URLs, use requests-aws4auth
from requests_aws4auth import AWS4Auth
import boto3

credentials = boto3.Session().get_credentials()
auth = AWS4Auth(
    credentials.access_key,
    credentials.secret_key,
    'us-east-1',
    'lambda',
    session_token=credentials.token
)

response = requests.post(
    function_url,
    json=payload,
    auth=auth,
    headers={"Content-Type": "application/json"}
)
```

### 7. Node.js (AWS SDK v3) Invocation

```javascript
import { LambdaClient, InvokeCommand } from "@aws-sdk/client-lambda";

const client = new LambdaClient({ region: "us-east-1" });

const payload = {
  key: "value",
  message: "Hello from Node.js"
};

// Synchronous invocation
const command = new InvokeCommand({
  FunctionName: "your-function-name",
  InvocationType: "RequestResponse",
  Payload: JSON.stringify(payload)
});

try {
  const response = await client.send(command);
  const result = JSON.parse(new TextDecoder().decode(response.Payload));

  console.log("Status Code:", response.StatusCode);
  console.log("Response:", result);
} catch (error) {
  console.error("Error:", error);
}

// Asynchronous invocation
const asyncCommand = new InvokeCommand({
  FunctionName: "your-function-name",
  InvocationType: "Event",
  Payload: JSON.stringify(payload)
});

const asyncResponse = await client.send(asyncCommand);
console.log("Async Status Code:", asyncResponse.StatusCode);
```

### 8. Node.js - HTTP Request to Function URL

```javascript
// For public Function URLs (auth_type = "NONE")
const functionUrl = "https://abcdefg.lambda-url.us-east-1.on.aws/";

const payload = {
  action: "process",
  data: { id: 123, name: "example" }
};

try {
  const response = await fetch(functionUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify(payload)
  });

  const result = await response.json();
  console.log("Status:", response.status);
  console.log("Response:", result);
} catch (error) {
  console.error("Error:", error);
}
```

### 9. Testing with Sample Events

You can test your Lambda with AWS-provided sample events:

```bash
# Create a sample S3 event
cat > s3-event.json <<EOF
{
  "Records": [
    {
      "eventVersion": "2.1",
      "eventSource": "aws:s3",
      "awsRegion": "us-east-1",
      "eventTime": "2024-01-01T12:00:00.000Z",
      "eventName": "ObjectCreated:Put",
      "s3": {
        "bucket": {
          "name": "my-bucket",
          "arn": "arn:aws:s3:::my-bucket"
        },
        "object": {
          "key": "test-file.txt",
          "size": 1024
        }
      }
    }
  ]
}
EOF

# Invoke with the S3 event
aws lambda invoke \
  --function-name "$FUNCTION_NAME" \
  --payload file://s3-event.json \
  response.json
```

### 10. Invoking from Terraform

You can also invoke the Lambda directly from Terraform for testing:

```hcl
# Deploy the Lambda
module "my_lambda" {
  source = "github.com/humanitec-tf-modules/serverless-lambda?ref=vX.Y.Z"

  s3_bucket = "my-deployment-bucket"
  s3_key    = "my-function.zip"
  runtime   = "python3.12"
  handler   = "lambda_function.lambda_handler"
}

# Invoke it for testing (using a data source)
data "aws_lambda_invocation" "test_invoke" {
  function_name = module.my_lambda.function_name

  input = jsonencode({
    key     = "value"
    message = "Test invocation from Terraform"
  })

  depends_on = [module.my_lambda]
}

output "lambda_test_result" {
  value = jsondecode(data.aws_lambda_invocation.test_invoke.result)
}
```

### Common Invocation Patterns

#### API Endpoint Pattern

```bash
# POST data
curl -X POST "$FUNCTION_URL/api/users" \
  -H "Content-Type: application/json" \
  -d '{"name": "John Doe", "email": "john@example.com"}'

# GET with query parameters
curl "$FUNCTION_URL/api/users?id=123"

# PUT to update
curl -X PUT "$FUNCTION_URL/api/users/123" \
  -H "Content-Type: application/json" \
  -d '{"name": "Jane Doe"}'

# DELETE
curl -X DELETE "$FUNCTION_URL/api/users/123"
```

#### Webhook Pattern

```bash
# GitHub webhook
curl -X POST "$FUNCTION_URL/webhook/github" \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: push" \
  -d '{"ref": "refs/heads/main", "repository": {"name": "my-repo"}}'

# Stripe webhook
curl -X POST "$FUNCTION_URL/webhook/stripe" \
  -H "Content-Type: application/json" \
  -H "Stripe-Signature: t=..." \
  -d '{"type": "payment_intent.succeeded", "data": {}}'
```

## Supported Runtimes

The module supports all AWS Lambda runtimes:

- **Python**: `python3.12`, `python3.11`, `python3.10`, `python3.9`
- **Node.js**: `nodejs20.x`, `nodejs18.x`
- **Java**: `java21`, `java17`, `java11`
- **Go**: `provided.al2023`, `provided.al2`
- **.NET**: `dotnet8`, `dotnet6`
- **Ruby**: `ruby3.3`, `ruby3.2`
- **Custom**: `provided.al2023`, `provided.al2`

## Architecture

This module creates the following AWS resources:

1. **Lambda Function** - The main function resource
2. **IAM Role** (optional) - Execution role for the Lambda function
3. **IAM Role Policy Attachment** - Attaches AWSLambdaBasicExecutionRole
4. **IAM Role Policy** - Inline policy for S3 access to the deployment package
5. **IAM Role Policy Attachments** (optional) - Additional managed policies
6. **IAM Role Policies** (optional) - Additional inline policies
7. **Lambda Function URL** (optional) - HTTP(S) endpoint for the function
8. **Random ID** - Generates unique suffix for function name

## Best Practices

### Security

1. **Principle of Least Privilege**: Only grant permissions the Lambda needs
2. **Use IAM Authentication**: For Function URLs, prefer `AWS_IAM` over `NONE` when possible
3. **Restrict CORS Origins**: Only allow specific origins, not `["*"]` in production
4. **Environment Variables**: Consider using AWS Secrets Manager or Parameter Store for sensitive data
5. **VPC Configuration**: If your Lambda needs to access VPC resources, configure VPC settings

### Performance

1. **Right-size Memory**: More memory = more CPU. Test to find optimal configuration
2. **Use ARM64**: Consider ARM64 architecture for better price/performance
3. **Minimize Package Size**: Smaller packages = faster cold starts
4. **Connection Reuse**: Reuse connections to databases and APIs across invocations

### Cost Optimization

1. **Set Appropriate Timeout**: Don't use the maximum if not needed
2. **Monitor Invocations**: Use CloudWatch metrics to track usage
3. **Use ARM64**: Can be up to 34% cheaper than x86_64

### Naming

The module automatically generates unique function names using:

- Your `name_prefix` (default: `"hum-orch-"`)
- A random 4-byte hex suffix

Example: `hum-orcha1b2c3d4`

## Testing

This module includes comprehensive tests. Run them with:

```bash
cd orchestrator-module-sources/serverless/lambda
terraform init
terraform test
```

The test suite validates:

- Basic Lambda function creation
- IAM role creation and policies
- Function URL configuration
- Environment variables and tags
- Custom IAM roles
- Multiple runtime configurations

## Additional Documentation

- [Lambda Function URL Configuration Examples](./USAGE-EXAMPLES.md) - Detailed IAM policy configuration examples
- [Test Invocations](./TEST-INVOCATIONS.md) - Manual testing instructions

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.lambda_additional_inline_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.s3_zip_bucket_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.lambda_additional_managed_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.lambda_basic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function_url.function_url](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function_url) | resource |
| [random_id.entropy](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_inline_policies"></a> [additional\_inline\_policies](#input\_additional\_inline\_policies) | Map of additional inline IAM policies to attach to the Lambda execution role. Key is the policy name, value is the policy document as JSON string | `map(string)` | `{}` | no |
| <a name="input_additional_managed_policy_arns"></a> [additional\_managed\_policy\_arns](#input\_additional\_managed\_policy\_arns) | List of additional managed IAM policy ARNs to attach to the Lambda execution role | `list(string)` | `[]` | no |
| <a name="input_additional_tags"></a> [additional\_tags](#input\_additional\_tags) | Additional tags to apply to the Lambda function | `map(string)` | `{}` | no |
| <a name="input_architectures"></a> [architectures](#input\_architectures) | Instruction set architecture for the Lambda function. Valid values: ['x86\_64'] or ['arm64'] | `list(string)` | <pre>[<br/>  "x86_64"<br/>]</pre> | no |
| <a name="input_enable_function_url"></a> [enable\_function\_url](#input\_enable\_function\_url) | If true, creates an HTTPS endpoint (Function URL) for the Lambda. Allows HTTP/HTTPS invocation. | `bool` | `false` | no |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | Environment variables to pass to the Lambda function | `map(string)` | `{}` | no |
| <a name="input_function_url_auth_type"></a> [function\_url\_auth\_type](#input\_function\_url\_auth\_type) | Authorization type for the Function URL. 'NONE' = public access, 'AWS\_IAM' = requires AWS credentials. | `string` | `"AWS_IAM"` | no |
| <a name="input_function_url_cors"></a> [function\_url\_cors](#input\_function\_url\_cors) | CORS configuration for the Function URL. Only applies if enable\_function\_url is true. | <pre>object({<br/>    allow_credentials = optional(bool, false)<br/>    allow_origins     = optional(list(string), ["*"])<br/>    allow_methods     = optional(list(string), ["*"])<br/>    allow_headers     = optional(list(string), [])<br/>    expose_headers    = optional(list(string), [])<br/>    max_age           = optional(number, 0)<br/>  })</pre> | `null` | no |
| <a name="input_handler"></a> [handler](#input\_handler) | The function entrypoint in your code (e.g., 'index.handler' for Node.js) | `string` | n/a | yes |
| <a name="input_iam_role_arn"></a> [iam\_role\_arn](#input\_iam\_role\_arn) | Optional IAM role ARN to use for the Lambda function. If not provided, a new role will be created | `string` | `null` | no |
| <a name="input_iam_role_name_prefix"></a> [iam\_role\_name\_prefix](#input\_iam\_role\_name\_prefix) | Prefix for the IAM role name. Only used when a new IAM role is created (iam\_role\_arn not provided) | `string` | `"lambda-role-"` | no |
| <a name="input_memory_size"></a> [memory\_size](#input\_memory\_size) | Amount of memory in MB that your Lambda function can use at runtime. Valid value between 128 MB to 10,240 MB | `number` | `128` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for the Lambda function name | `string` | `"hum-orch-"` | no |
| <a name="input_runtime"></a> [runtime](#input\_runtime) | The Lambda runtime identifier (e.g., 'python3.12', 'nodejs20.x', 'java21') | `string` | n/a | yes |
| <a name="input_s3_bucket"></a> [s3\_bucket](#input\_s3\_bucket) | The S3 bucket name where the Lambda deployment package (zip) is stored | `string` | n/a | yes |
| <a name="input_s3_key"></a> [s3\_key](#input\_s3\_key) | The S3 object key (path) for the Lambda deployment package | `string` | n/a | yes |
| <a name="input_timeout_in_seconds"></a> [timeout\_in\_seconds](#input\_timeout\_in\_seconds) | The amount of time the Lambda function has to run in seconds | `number` | `300` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_function_arn"></a> [function\_arn](#output\_function\_arn) | The ARN of the Lambda function |
| <a name="output_function_name"></a> [function\_name](#output\_function\_name) | The name of the Lambda function |
| <a name="output_function_url"></a> [function\_url](#output\_function\_url) | The HTTPS URL endpoint for the Lambda function (if enable\_function\_url is true) |
| <a name="output_humanitec_metadata"></a> [humanitec\_metadata](#output\_humanitec\_metadata) | The Humanitec metadata annotations for the Lambda function |
| <a name="output_invoke_arn"></a> [invoke\_arn](#output\_invoke\_arn) | The ARN to be used for invoking the Lambda function from API Gateway |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | The ARN of the IAM role used by the Lambda function |
<!-- END_TF_DOCS -->