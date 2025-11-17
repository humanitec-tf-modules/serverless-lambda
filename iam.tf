resource "aws_iam_role" "role" {
  count       = local.create_lambda_role ? 1 : 0
  name_prefix = var.iam_role_name_prefix
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  tags = var.additional_tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = local.create_lambda_role ? aws_iam_role.role[0].name : split("/", var.iam_role_arn)[1]
}

resource "aws_iam_role_policy" "s3_zip_bucket_access" {
  count = local.create_lambda_role ? 1 : 0
  role  = aws_iam_role.role[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = "arn:aws:s3:::${var.s3_bucket}/${var.s3_key}"
      }
    ]
  })
}

# Attach additional managed policies to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_additional_managed_policies" {
  for_each = local.create_lambda_role ? toset(var.additional_managed_policy_arns) : []

  role       = aws_iam_role.role[0].name
  policy_arn = each.value
}

# Attach additional inline policies to the Lambda role
resource "aws_iam_role_policy" "lambda_additional_inline_policies" {
  for_each = local.create_lambda_role ? var.additional_inline_policies : {}

  role   = aws_iam_role.role[0].id
  name   = each.key
  policy = each.value
}
