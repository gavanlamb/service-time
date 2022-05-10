data "aws_vpc" "vpc" {
  tags = {
    Name = var.vpc_name
  }
}
data "aws_subnets" "private" {
  vpc_id = data.aws_vpc.vpc.id

  tags = {
    Tier = "private"
  }
}
data "aws_security_group" "external" {
  vpc_id = data.aws_vpc.vpc.id
  name = "external"
}
data "aws_db_subnet_group" "database"{
  name = var.db_subnet_group_name
}

data "aws_iam_role" "codedeploy"{
  name = var.codedeploy_role_name
}

data "aws_route53_zone" "expensely_io" {
  name = var.zone_name
}

data "aws_lb" "expensely" {
  name = var.alb_name
}
data "aws_lb_listener" "expensely_https" {
  load_balancer_arn = data.aws_lb.expensely.arn
  port = 443
}
data "aws_lb_listener" "expensely_test" {
  load_balancer_arn = data.aws_lb.expensely.arn
  port = 8443
}

data "aws_kms_alias" ssm_default_key{
  name = "alias/aws/ssm"
}

data "aws_ecr_repository" "api" {
  name = "${lower(var.application_name)}-api"
}
data "aws_ecr_repository" "migrator" {
  name = "${lower(var.application_name)}-migrator"
}
data "aws_ecr_repository" "lambda_postman" {
  count = local.isProduction ? 0 : 1
  name = "lambda-postman"
}
data "aws_ecr_repository" "load_tests" {
  count = local.isProduction ? 0 : 1
  name = "lambda-jmeter"
}

data "aws_iam_policy" "codedeploy_bucket"{
  name = var.codedeploy_bucket_policy_name
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "api_task" {
  version = "2008-10-17"
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = [
        "ecs-tasks.amazonaws.com",
        "ecs.amazonaws.com"
      ]
      type = "Service"
    }
    effect = "Allow"
  }
}
data "aws_iam_policy_document" "api_execution" {
  version = "2008-10-17"
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = [
        "ecs-tasks.amazonaws.com",
        "ecs.amazonaws.com"
      ]
      type = "Service"
    }
    effect = "Allow"
  }
}
