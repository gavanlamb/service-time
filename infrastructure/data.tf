data "aws_vpc" "vpc" {
  tags = {
    Name = var.vpc_name
  }
}
data "aws_subnet_ids" "private" {
  vpc_id = data.aws_vpc.vpc.id

  tags = {
    Tier = "private"
  }
}
data "aws_security_group" "postgres_client" {
  vpc_id = data.aws_vpc.vpc.id
  name = "expensely-rds-client"
}
data "aws_security_group" "external" {
  vpc_id = data.aws_vpc.vpc.id
  name = "external"
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

data "aws_kms_alias" ssm_default_key{
  name = "alias/aws/ssm"
}

data "aws_ecr_repository" "api" {
  name = "${lower(var.application_name)}-api"
}
data "aws_ecr_repository" "migration" {
  name = "${lower(var.application_name)}-migration"
}

data "aws_cognito_user_pools" "expensely" {
  name = var.cognito_name
}

data "aws_caller_identity" "current" {}