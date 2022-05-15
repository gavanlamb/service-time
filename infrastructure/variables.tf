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
variable "codedeploy_bucket_policy_name" {
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
variable "db_subnet_group_name"{
  type = string
}

variable "rds_delete_protection" {
  type = bool
}
variable "rds_database_name" {
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
  rds_name = "${lower(var.application_name)}-${lower(var.environment)}"
  rds_username = module.postgres.rds_cluster_master_username
  rds_password = module.postgres.rds_cluster_master_password
  rds_port = module.postgres.rds_cluster_port
  rds_endpoint = replace(module.postgres.rds_cluster_endpoint, ":${module.postgres.rds_cluster_port}", "")
  
  api_name = "${lower(var.application_name)}-${lower(var.environment)}"
  migrator_name = "${lower(var.application_name)}-migrator-${lower(var.environment)}"
  api_tests_name = "${lower(var.application_name)}-api-tests-${lower(var.environment)}"
  load_tests_name = "${lower(var.application_name)}-load-tests-${lower(var.environment)}"
  open_telemetry_name = "open-telemetry-${lower(var.environment)}"

  api_url = "${var.subdomain}.${trimsuffix(data.aws_route53_zone.expensely_io.name, ".")}"
  
  s3_base_path = "${lower(var.application_name)}/${var.build_identifier}/${lower(var.environment)}"

  isProduction = var.environment == "Production"
  
  defaultDashboard = ""
  
  default_tags = {
    Service = var.application_name
    Application = "Tracker"
    Team = "Tracker"
    ManagedBy = "Terraform"
    Environment = var.environment
  }
}
