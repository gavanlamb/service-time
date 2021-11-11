variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "application_name" {
  type = string
  default = "Time"
}

variable "build_identifier" {
  type = string
}

variable "vpc_name" {
  type = string
  default = null
}

variable "cluster_name" {
  type = string
  default = null
}
variable "capacity_provider_name" {
  type = string
  default = null
}

variable "cognito_name" {
  type = string
  default = null
}

variable "codedeploy_role_name" {
  type = string
  default = null
}
variable "codedeploy_bucket_name" {
  type = string
  default = null
}

variable "zone_name" {
  type = string
  default = null
}
variable "subdomain" {
  type = string
  default = "platform"
}
variable "alb_name" {
  type = string
  default = null
}

variable "api_ecs_task_cpu" {
  type = number
  default = 1024
}
variable "api_ecs_task_memory" {
  type = number
  default = 2042
}
variable "api_min_capacity"{
  type = number
  default = 2
}
variable "api_max_capacity"{
  type = number
  default = 10
}
variable "api_desired_count"{
  type = number
  default = 2
}
variable "npm_build_identifier"{
  type = string
}
variable "results_bucket"{
  type = string
}

variable "placement_strategies"{
  type = list(object({type:string, field:string}))
  description = "ECS task placement strategy"
  default = [
    {
      field = "cpu"
      type = "binpack"
    }
  ]
}
###################################################
# LOCALS
###################################################
locals {
  api_name = "${lower(var.application_name)}-${lower(var.environment)}"
  migration_name = "${lower(var.application_name)}-migration-${lower(var.environment)}"
  integration_tests_name = "${lower(var.application_name)}-integration-tests-${lower(var.environment)}"

  api_url = "${var.subdomain}.${trimsuffix(data.aws_route53_zone.expensely_io.name, ".")}"

  default_tags = {
    Application = "Expensely"
    Team = "Time"
    ManagedBy = "Terraform"
    Environment = var.environment
  }
}
