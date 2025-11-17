data "aws_region" "current" {}

locals {
  create_lambda_role = var.iam_role_arn == null ? true : false
  aws_region         = data.aws_region.current.region
}

