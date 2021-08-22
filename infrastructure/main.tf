resource "aws_codedeploy_deployment_group" "api" {
  deployment_group_name = "${local.api_name}-dg"
  app_name = aws_codedeploy_app.api.name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn = data.aws_iam_role.codedeploy.arn

  auto_rollback_configuration {
    enabled = true
    events = [
      "DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action = "TERMINATE"
      termination_wait_time_in_minutes = 2
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = var.cluster_name
    service_name = aws_ecs_service.api.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [
          data.aws_lb_listener.expensely_https.arn
        ]
      }

      target_group {
        name = aws_alb_target_group.api_blue.name
      }

      target_group {
        name = aws_alb_target_group.api_green.name
      }
    }
  }
}
resource "aws_codedeploy_app" "api" {
  compute_platform = "ECS"
  name = local.api_name
}
resource "local_file" "api_app_spec" {
  content_base64 = base64encode(data.template_file.api_app_spec.rendered)
  filename = "${lower(var.application_name)}-${var.build_identifier}.yaml"
}
data "template_file" "api_app_spec" {
  template = file("./templates/codedeploy.yml")

  vars = {
    application_task_definition = aws_ecs_task_definition.api.arn
    application_container_name = local.api_name
    migration_lambda_arn = aws_lambda_function.migration.qualified_arn
  }
}

resource "local_file" "code_deployment" {
  content_base64 = base64encode(data.template_file.code_deployment.rendered)
  filename = "create-deployment.json"
}
data "template_file" "code_deployment" {
  template = file("./templates/create-deployment.json")

  vars = {
    codedeploy_bucket_name = var.codedeploy_bucket_name
    app_spec_key = "${lower(var.application_name)}/${lower(var.environment)}/${lower(var.application_name)}-${var.build_identifier}.yaml"
    deployment_group_name = aws_codedeploy_deployment_group.api.deployment_group_name
    application_name = aws_codedeploy_app.api.name
  }
}

// Migrations
/// Lambda
resource "aws_lambda_function" "migration" {
  function_name = local.migration_name
  role = aws_iam_role.migration.arn
  description = "Time database migrations"

  package_type = "Image"
  publish = true

  image_uri = "${data.aws_ecr_repository.migration.repository_url}:${var.build_identifier}"

  memory_size = 2048

  reserved_concurrent_executions = 1

  timeout = 900

  vpc_config {
    security_group_ids = [
      data.aws_security_group.postgres_client.id,
      data.aws_security_group.external.id]
    subnet_ids = data.aws_subnet_ids.database.ids
  }
  
  environment {
    variables = {
      DOTNET_ENVIRONMENT = var.environment
    }
  }

  tags = local.default_tags
}

/// IAM 
resource "aws_iam_role" "migration" {
  name = local.migration_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "migration_vpc" {
  role = aws_iam_role.migration.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
resource "aws_iam_role_policy_attachment" "migration_codedeploy" {
  role = aws_iam_role.migration.name
  policy_arn = aws_iam_policy.migration_codedeploy.arn
}
resource "aws_iam_role_policy_attachment" "migration_ssm_read" {
  role = aws_iam_role.migration.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}
resource "aws_iam_role_policy_attachment" "migration_vpc_exec" {
  role = aws_iam_role.migration.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
resource "aws_iam_policy" "migration_codedeploy" {
  name = "${local.api_name}-codedeploy"
  policy = data.aws_iam_policy_document.migration_codedeploy.json
}
data "aws_iam_policy_document" "migration_codedeploy" {
  statement {
    effect = "Allow"
    actions = [
      "codedeploy:PutLifecycleEventHookExecutionStatus"
    ]
    resources = [
      "arn:aws:codedeploy:${var.region}:${data.aws_caller_identity.current.account_id}:deploymentgroup:${aws_codedeploy_app.api.name}/${aws_codedeploy_deployment_group.api.deployment_group_name}"
    ]
  }
}

// API
/// ROUTE53
resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.expensely_io.zone_id
  name = var.subdomain
  type = "A"

  alias {
    name = data.aws_lb.expensely.dns_name
    zone_id = data.aws_lb.expensely.zone_id
    evaluate_target_health = true
  }
}

/// ECS
resource "aws_ecs_service" "api" {
  name = "${local.api_name}-service"
  cluster = var.cluster_name
  deployment_maximum_percent = 200
  deployment_minimum_healthy_percent = 50
  desired_count = var.api_desired_count
  enable_ecs_managed_tags = true
  health_check_grace_period_seconds = 120
  scheduling_strategy = "REPLICA"
  task_definition = aws_ecs_task_definition.api.arn

  dynamic "ordered_placement_strategy" {
    for_each = var.placement_strategies
    content {
      type = ordered_placement_strategy.value.type
      field = ordered_placement_strategy.value.field
    }
  }

  capacity_provider_strategy {
    base = var.api_min_capacity
    capacity_provider = var.capacity_provider_name
    weight = 100
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.api_blue.id
    container_name = local.api_name
    container_port = 80
  }

  tags = local.default_tags
  propagate_tags = "TASK_DEFINITION"

  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count,
      load_balancer]
  }
}
resource "aws_ecs_task_definition" "api" {
  family = "${local.api_name}-task"

  requires_compatibilities = [
    "EC2"]

  execution_role_arn = aws_iam_role.api_execution.arn
  task_role_arn = aws_iam_role.api_task.arn

  container_definitions = jsonencode([
    {
      name = local.api_name
      image = "${data.aws_ecr_repository.api.repository_url}:${var.build_identifier}"
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group = aws_cloudwatch_log_group.api.name
          awslogs-region = var.region
          awslogs-stream-prefix = "/ecs"
        }
      }
      cpu = var.api_ecs_task_cpu
      memory = var.api_ecs_task_memory

      environment = [
        {
          name = "DOTNET_ENVIRONMENT",
          value = var.environment
        }
      ]
      portMappings = [
        {
          protocol = "tcp"
          containerPort = 80
        }
      ]
    }
  ])

  tags = local.default_tags
}
resource "aws_appautoscaling_target" "api_ecs_target" {
  min_capacity = var.api_min_capacity
  max_capacity = var.api_max_capacity
  resource_id = "service/${var.cluster_name}/${aws_ecs_service.api.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace = "ecs"
}
resource "aws_appautoscaling_policy" "api_ecs_policy_cpu" {
  name = "${local.api_name}-cpu-autoscaling"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.api_ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.api_ecs_target.scalable_dimension
  service_namespace = aws_appautoscaling_target.api_ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 70
    scale_in_cooldown = 300
    scale_out_cooldown = 300
  }
}
resource "aws_appautoscaling_policy" "api_ecs_policy_memory" {
  name = "${local.api_name}-memory-autoscaling"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.api_ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.api_ecs_target.scalable_dimension
  service_namespace = aws_appautoscaling_target.api_ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = 70
    scale_in_cooldown = 300
    scale_out_cooldown = 300
  }
}

/// ALB
resource "aws_lb_listener_rule" "api" {
  listener_arn = data.aws_lb_listener.expensely_https.arn

  action {
    type = "forward"
    target_group_arn = aws_alb_target_group.api_blue.arn
  }

  condition {
    host_header {
      values = [
        local.api_url]
    }
  }

  lifecycle {
    ignore_changes = [
      action
    ]
  }
}
resource "aws_alb_target_group" "api_blue" {
  name = "${local.api_name}-blue"
  port = 80
  protocol = "HTTP"
  vpc_id = data.aws_vpc.vpc.id
  target_type = "instance"

  health_check {
    enabled = true
    interval = 180
    matcher = "200"
    timeout = 20
    path = "/health"
  }

  tags = local.default_tags
}
resource "aws_alb_target_group" "api_green" {
  name = "${local.api_name}-green"
  port = aws_alb_target_group.api_blue.port
  protocol = aws_alb_target_group.api_blue.protocol
  vpc_id = aws_alb_target_group.api_blue.vpc_id
  target_type = aws_alb_target_group.api_blue.target_type


  health_check {
    enabled = aws_alb_target_group.api_blue.health_check[0].enabled
    interval = aws_alb_target_group.api_blue.health_check[0].interval
    matcher = aws_alb_target_group.api_blue.health_check[0].matcher
    timeout = aws_alb_target_group.api_blue.health_check[0].timeout
    path = aws_alb_target_group.api_blue.health_check[0].path
  }

  tags = aws_alb_target_group.api_blue.tags
}

/// Cloudwatch
resource "aws_cloudwatch_log_group" "api" {
  name = "/${lower(var.application_name)}/${lower(var.environment)}"
  retention_in_days = 14
  tags = local.default_tags
}
resource "aws_iam_policy" "api_logs" {
  name = "${local.api_name}-logs"
  policy = data.aws_iam_policy_document.api_logs.json
}
data "aws_iam_policy_document" "api_logs" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups"
    ]
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

/// IAM
//// Task
resource "aws_iam_role" "api_task" {
  name = "${local.api_name}-task-role"
  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "ecs-tasks.amazonaws.com",
          "ecs.amazonaws.com"
        ]
      },
      "Effect": "Allow"
    }
  ]
}
EOF

  tags = local.default_tags
}
resource "aws_iam_role_policy_attachment" "api_logs_task" {
  role = aws_iam_role.api_task.name
  policy_arn = aws_iam_policy.api_logs.arn
}

//// Execution
resource "aws_iam_role" "api_execution" {
  name = "${local.api_name}-execution-role"
  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "ecs-tasks.amazonaws.com",
          "ecs.amazonaws.com"
        ]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
  tags = local.default_tags
}
resource "aws_iam_role_policy_attachment" "api_execution_role_policy" {
  role = aws_iam_role.api_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_iam_role_policy_attachment" "api_logs_execution" {
  role = aws_iam_role.api_execution.name
  policy_arn = aws_iam_policy.api_logs.arn
}

resource "aws_iam_role_policy_attachment" "api_secrets" {
  role = aws_iam_role.api_execution.name
  policy_arn = aws_iam_policy.api_secrets.arn
}
resource "aws_iam_policy" "api_secrets" {
  name = "${local.api_name}-secrets-access"
  policy = data.aws_iam_policy_document.api_secrets.json
}
data "aws_iam_policy_document" "api_secrets" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters",
      "secretsmanager:GetSecretValue",
      "kms:Decrypt"
    ]
    resources = [
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.application_name}/${var.environment}/*",
      data.aws_kms_alias.ssm_default_key.target_key_arn
    ]
  }
}

// Cognito
resource "aws_cognito_resource_server" "resource" {
  identifier = "https://${aws_route53_record.api.fqdn}"
  name = lower(var.application_name)

  scope {
    scope_name = "time:create"
    scope_description = "Permission to create records for Time API"
  }
  scope {
    scope_name = "time:delete"
    scope_description = "Permission to delete records for Time API"
  }
  scope {
    scope_name = "time:read"
    scope_description = "Permission to read records for Time API"
  }
  scope {
    scope_name = "time:update"
    scope_description = "Permission to update records for Time API"
  }

  user_pool_id = sort(data.aws_cognito_user_pools.expensely.ids)[0]
}