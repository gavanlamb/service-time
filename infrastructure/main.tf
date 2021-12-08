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
      
      test_traffic_route {
        listener_arns = [
          data.aws_lb_listener.expensely_test.arn
        ]
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
  filename = "${var.build_identifier}.yaml"
}
data "template_file" "api_app_spec" {
  template = file("./templates/codedeploy.yml")

  vars = {
    application_task_definition = aws_ecs_task_definition.api.arn
    application_container_name = local.api_name
    migration_lambda_arn = aws_lambda_function.migration.qualified_arn
    integration_tests_lambda_arn = aws_lambda_function.integration_tests.qualified_arn
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
    app_spec_key = "${lower(var.application_name)}/${lower(var.environment)}/${var.build_identifier}.yaml"
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
      aws_security_group.postgres_client.id,
      data.aws_security_group.external.id]
    subnet_ids = data.aws_subnet_ids.private.ids
  }
  
  environment {
    variables = {
      DOTNET_ENVIRONMENT = var.environment
    }
  }
}

/// Cloudwatch
resource "aws_cloudwatch_log_group" "migration" {
  name = "/aws/lambda/${aws_lambda_function.migration.function_name}"
  retention_in_days = 14
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
  policy_arn = aws_iam_policy.codedeploy.arn
}
resource "aws_iam_role_policy_attachment" "migration_ssm_read" {
  role = aws_iam_role.migration.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
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
resource "aws_lb_listener_rule" "test" {
  listener_arn = data.aws_lb_listener.expensely_test.arn

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
}

/// Cloudwatch
resource "aws_cloudwatch_log_group" "api" {
  name = "/${lower(var.application_name)}/${lower(var.environment)}"
  retention_in_days = 14
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
}
resource "aws_iam_role_policy_attachment" "api_task_logs_task" {
  role = aws_iam_role.api_task.name
  policy_arn = aws_iam_policy.api_logs.arn
}
resource "aws_iam_role_policy_attachment" "api_task_parameters" {
  role = aws_iam_role.api_task.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}
resource "aws_iam_role_policy_attachment" "api_task_cognito" {
  role = aws_iam_role.api_task.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonCognitoReadOnly"
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
}
resource "aws_iam_role_policy_attachment" "api_execution_role_policy" {
  role = aws_iam_role.api_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_iam_role_policy_attachment" "api_execution_logs" {
  role = aws_iam_role.api_execution.name
  policy_arn = aws_iam_policy.api_logs.arn
}
resource "aws_iam_role_policy_attachment" "api_execution_parameters" {
  role = aws_iam_role.api_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

// Integration tests
/// lambda
resource "aws_lambda_function" "integration_tests" {
  function_name = local.integration_tests_name
  role = aws_iam_role.integration_tests.arn
  description = "Time integration tests"

  package_type = "Image"
  publish = true

  image_uri = "${data.aws_ecr_repository.integration_tests.repository_url}:${var.npm_build_identifier}"

  memory_size = 2048

  reserved_concurrent_executions = 1

  timeout = 900

  environment {
    variables = {
      ENVIRONMENT = lower(var.environment),
      BUILD_NUMBER = var.npm_build_identifier,
      RESULTS_BUCKET = var.test_results_bucket,
      BASEURL = "https://${local.api_url}:8443"
    }
  }
}
/// cloudwatch
resource "aws_cloudwatch_log_group" "integration_tests" {
  name = "/aws/lambda/${aws_lambda_function.integration_tests.function_name}"
  retention_in_days = 14
}
/// IAM
resource "aws_iam_role" "integration_tests" {
  name = local.integration_tests_name

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
resource "aws_iam_role_policy_attachment" "integration_tests_vpc" {
  role = aws_iam_role.integration_tests.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
resource "aws_iam_role_policy_attachment" "integration_tests_codedeploy" {
  role = aws_iam_role.integration_tests.name
  policy_arn = aws_iam_policy.codedeploy.arn
}
resource "aws_iam_role_policy_attachment" "integration_tests_bucket_upload" {
  role = aws_iam_role.integration_tests.name
  policy_arn = data.aws_iam_policy.test_results_bucket.arn
}

// Shared IAM 
resource "aws_iam_policy" "codedeploy" {
  name = "${local.api_name}-codedeploy"
  policy = data.aws_iam_policy_document.codedeploy.json
}
data "aws_iam_policy_document" "codedeploy" {
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

// RDS
module "postgres" {
  source = "terraform-aws-modules/rds-aurora/aws"
  version = "5.2.0"

  name = local.rds_name
  engine = "aurora-postgresql"
  engine_mode = "serverless"
  storage_encrypted = true

  vpc_id = data.aws_vpc.vpc.id
  subnets = data.aws_db_subnet_group.database.subnet_ids
  db_subnet_group_name = data.aws_db_subnet_group.database.name
  create_security_group = false
  vpc_security_group_ids = [aws_security_group.postgres_server.id]

  replica_scale_enabled = false
  replica_count = 0

  monitoring_interval = 60

  apply_immediately = true
  skip_final_snapshot = true

  db_parameter_group_name = aws_db_parameter_group.postgresql.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.postgresql.id

  deletion_protection = var.rds_delete_protection
  
  database_name = var.rds_database_name

  scaling_configuration = {
    auto_pause = true
    min_capacity = 2
    max_capacity = 4
    seconds_until_auto_pause = 300
    timeout_action = "ForceApplyCapacityChange"
  }
}
resource "aws_db_parameter_group" "postgresql" {
  name = "${local.rds_name}-aurora-pg-parameter-group"
  family = "aurora-postgresql10"
  description = "Parameter group for ${local.rds_name}"
}
resource "aws_rds_cluster_parameter_group" "postgresql" {
  name = "${local.rds_name}-aurora-pg-cluster-parameter-group"
  family = "aurora-postgresql10"
  description = "Cluster parameter group for ${local.rds_name}"
}

resource "aws_secretsmanager_secret" "postgres_admin_password" {
  name = "Expensely/${var.environment}/DatabaseInstance/Postgres/User/Expensely"
  description = "Admin password for RDS instance:${module.postgres.rds_cluster_id}"
}
resource "aws_secretsmanager_secret_version" "postgres_admin_password" {
  secret_id = aws_secretsmanager_secret.postgres_admin_password.id
  secret_string = jsonencode({
    Username = local.rds_username,
    Password = local.rds_password,
    Port = local.rds_port,
    Endpoint = local.rds_endpoint
  })
}

resource "aws_security_group" "postgres_server" {
  name = "${local.rds_name}-rds-server"
  description = "Allow traffic into RDS:expensely"
  vpc_id = data.aws_vpc.vpc.id

  tags = {
    Name = "${local.rds_name}-rds-server"
  }
}
resource "aws_security_group_rule" "postgres_server" {
  security_group_id = aws_security_group.postgres_server.id

  type = "ingress"
  from_port = module.postgres.rds_cluster_port
  to_port = module.postgres.rds_cluster_port
  protocol = "tcp"
  source_security_group_id = aws_security_group.postgres_client.id
  description = "Allow traffic from ${aws_security_group.postgres_client.name} on port ${module.postgres.rds_cluster_port}"
}
resource "aws_security_group_rule" "external" {
  security_group_id = aws_security_group.postgres_server.id

  type = "ingress"
  from_port = module.postgres.rds_cluster_port
  to_port = module.postgres.rds_cluster_port
  protocol = "tcp"
  source_security_group_id = data.aws_security_group.external.id
  description = "Allow traffic from ${data.aws_security_group.external.name} on port ${module.postgres.rds_cluster_port}"
}

resource "aws_security_group" "postgres_client" {
  name = "${local.rds_name}-rds-client"
  description = "Allow traffic to RDS:${local.rds_name}"
  vpc_id = data.aws_vpc.vpc.id

  tags = {
    Name = "${local.rds_name}-rds-client"
  }
}
resource "aws_security_group_rule" "postgres_client" {
  security_group_id = aws_security_group.postgres_client.id

  type = "egress"
  from_port = module.postgres.rds_cluster_port
  to_port = module.postgres.rds_cluster_port
  protocol = "tcp"
  source_security_group_id = aws_security_group.postgres_server.id
  description = "Allow traffic to ${aws_security_group.postgres_server.name} on port ${module.postgres.rds_cluster_port}"
}

resource "aws_ssm_parameter" "connection_string" {
  name  = "/${var.application_name}/${var.environment}/ConnectionStrings/Default"
  type  = "SecureString"
  value = "Host=${local.rds_endpoint};Port=${local.rds_port};Database=${var.rds_database_name};Username=${local.rds_username};Password=${local.rds_password};Keepalive=300;CommandTimeout=300;Timeout=300"
}

// Cloudwatch
/// Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = local.api_name
  dashboard_body = <<EOF
{
    "widgets": [
        {
            "height": 6,
            "width": 18,
            "y": 29,
            "x": 6,
            "type": "log",
            "properties": {
                "query": "SOURCE '/time/preview21' | fields Properties.AssemblyVersion as Version, MessageTemplate as Template\n| filter Level = \"Information\"\n| stats count(*) as Count by Template, Version\n| sort Count desc\n| display Count, Version, Template\n| limit 20",
                "region": "ap-southeast-2",
                "stacked": false,
                "title": "Top information templates",
                "view": "table"
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 0,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '/time/preview21' | fields Properties.StatusCode as Code\n| filter MessageTemplate = \"HTTP {RequestMethod} {RequestPath} responded {StatusCode} in {Elapsed:0.0000} ms\"\n| filter Properties.RequestPath != \"/health\"\n| stats count(*) as Count by Code\n| sort by Code\n",
                "region": "ap-southeast-2",
                "stacked": false,
                "title": "Response codes",
                "view": "pie"
            }
        },
        {
            "height": 1,
            "width": 24,
            "y": 57,
            "x": 0,
            "type": "text",
            "properties": {
                "markdown": "## Health "
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 58,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '/time/preview21' | fields Properties.StatusCode\n| filter MessageTemplate = \"HTTP {RequestMethod} {RequestPath} responded {StatusCode} in {Elapsed:0.0000} ms\"\n| filter Properties.RequestPath = \"/health\"\n| stats count(*) as Count by Properties.StatusCode\n",
                "region": "ap-southeast-2",
                "stacked": false,
                "view": "pie",
                "title": "Response codes"
            }
        },
        {
            "height": 6,
            "width": 18,
            "y": 0,
            "x": 6,
            "type": "log",
            "properties": {
                "query": "SOURCE '/time/preview21' | fields Properties.Elapsed\n| filter MessageTemplate = \"HTTP {RequestMethod} {RequestPath} responded {StatusCode} in {Elapsed:0.0000} ms\"\n| filter Properties.RequestPath != \"/health\"\n| stats min(Properties.Elapsed)as min, avg(Properties.Elapsed) as avg, max(Properties.Elapsed) as max by bin(1m)\n",
                "region": "ap-southeast-2",
                "stacked": false,
                "title": "Request elapsed ms",
                "view": "timeSeries"
            }
        },
        {
            "height": 6,
            "width": 18,
            "y": 58,
            "x": 6,
            "type": "log",
            "properties": {
                "query": "SOURCE '/time/preview21' | fields Properties.Elapsed\n| filter MessageTemplate = \"HTTP {RequestMethod} {RequestPath} responded {StatusCode} in {Elapsed:0.0000} ms\"\n| filter Properties.RequestPath = \"/health\"\n| stats min(Properties.Elapsed)as min, avg(Properties.Elapsed) as avg, max(Properties.Elapsed) as max by bin(1m)\n",
                "region": "ap-southeast-2",
                "stacked": false,
                "title": "Request elapsed ms",
                "view": "timeSeries"
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 65,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "ReadIOPS", "DBClusterIdentifier", "time-preview21", { "yAxis": "right", "label": "Read" } ],
                    [ ".", "WriteIOPS", ".", ".", { "label": "Write" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "ap-southeast-2",
                "period": 60,
                "stat": "Sum",
                "title": "IOPS",
                "yAxis": {
                    "left": {
                        "min": 0,
                        "showUnits": false
                    },
                    "right": {
                        "min": 0,
                        "showUnits": true
                    }
                },
                "liveData": true,
                "annotations": {
                    "vertical": [
                        {
                            "label": "1.0.2213.1",
                            "value": "2021-11-20T01:39:02.000Z"
                        }
                    ]
                }
            }
        },
        {
            "height": 1,
            "width": 24,
            "y": 64,
            "x": 0,
            "type": "text",
            "properties": {
                "markdown": "# RDS "
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 51,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "CPUUtilization", "DBClusterIdentifier", "time-preview21", { "label": "Utilization" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "ap-southeast-2",
                "stat": "Average",
                "period": 60,
                "title": "CPU",
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                },
                "legend": {
                    "position": "bottom"
                },
                "setPeriodToTimeRange": true,
                "annotations": {
                    "vertical": [
                        {
                            "label": "1.0.2213.1",
                            "value": "2021-11-20T01:39:02.000Z"
                        }
                    ]
                },
                "liveData": true
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 51,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "FreeableMemory", "DBClusterIdentifier", "time-preview21", { "label": "Freeable" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "ap-southeast-2",
                "period": 60,
                "stat": "Average",
                "title": "Memory",
                "yAxis": {
                    "left": {
                        "min": 0,
                        "showUnits": false
                    }
                },
                "annotations": {
                    "vertical": [
                        {
                            "label": "1.0.2213.1",
                            "value": "2021-11-20T01:39:02.000Z"
                        }
                    ]
                },
                "liveData": true
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 45,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "FreeLocalStorage", "DBClusterIdentifier", "time-preview21", { "label": "Free Local" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "ap-southeast-2",
                "stat": "Average",
                "period": 60,
                "title": "Storage",
                "liveData": true,
                "annotations": {
                    "vertical": [
                        {
                            "label": "1.0.2213.1",
                            "value": "2021-11-20T01:39:02.000Z"
                        }
                    ]
                },
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 71,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "DatabaseConnections", "DBClusterIdentifier", "time-preview21", { "label": "Connections" } ]
                ],
                "view": "timeSeries",
                "stacked": true,
                "region": "ap-southeast-2",
                "stat": "Average",
                "period": 60,
                "title": "Connections",
                "yAxis": {
                    "left": {
                        "min": 0,
                        "label": ""
                    }
                },
                "liveData": true,
                "legend": {
                    "position": "hidden"
                },
                "annotations": {
                    "vertical": [
                        {
                            "label": "1.0.2213.1",
                            "value": "2021-11-20T01:39:02.000Z"
                        }
                    ]
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 65,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "Deadlocks", "DBClusterIdentifier", "time-preview21" ]
                ],
                "view": "timeSeries",
                "stacked": true,
                "region": "ap-southeast-2",
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                },
                "legend": {
                    "position": "hidden"
                },
                "title": "Deadlocks",
                "period": 60,
                "liveData": true,
                "stat": "Average",
                "annotations": {
                    "vertical": [
                        {
                            "label": "1.0.2213.1",
                            "value": "2021-11-20T01:39:02.000Z"
                        }
                    ]
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 77,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "ServerlessDatabaseCapacity", "DBClusterIdentifier", "time-preview21", { "label": "ServerlessDatabaseCapacity" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "ap-southeast-2",
                "stat": "Average",
                "period": 60,
                "title": "Capacity",
                "legend": {
                    "position": "hidden"
                },
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                },
                "liveData": true,
                "annotations": {
                    "vertical": [
                        {
                            "label": "1.0.2213.1",
                            "value": "2021-11-20T01:39:02.000Z"
                        }
                    ]
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 71,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "AuroraReplicaLag", "DBClusterIdentifier", "time-preview21" ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "ap-southeast-2",
                "title": "Replica lag",
                "stat": "Average",
                "period": 60,
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                },
                "liveData": true,
                "annotations": {
                    "vertical": [
                        {
                            "label": "1.0.2213.1",
                            "value": "2021-11-20T01:39:02.000Z"
                        }
                    ]
                }
            }
        },
        {
            "height": 6,
            "width": 24,
            "y": 6,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '/time/preview21' | fields MessageTemplate as Template, Level\n| stats count(*) as Count by Template, Level\n| sort Count desc\n| display Count, Level, Template\n| limit 20",
                "region": "ap-southeast-2",
                "stacked": false,
                "title": "Top log templates",
                "view": "table"
            }
        },
        {
            "height": 6,
            "width": 18,
            "y": 23,
            "x": 6,
            "type": "log",
            "properties": {
                "query": "SOURCE '/time/preview21' | fields Properties.AssemblyVersion as Version, MessageTemplate as Template\n| filter Level = \"Warning\"\n| stats count(*) as Count by Template, Version\n| sort Count desc\n| display Count, Version, Template\n| limit 20",
                "region": "ap-southeast-2",
                "stacked": false,
                "title": "Top warning templates",
                "view": "table"
            }
        },
        {
            "height": 6,
            "width": 18,
            "y": 17,
            "x": 6,
            "type": "log",
            "properties": {
                "query": "SOURCE '/time/preview21' | fields Properties.AssemblyVersion as Version, MessageTemplate as Template\n| filter Level = \"Error\"\n| stats count(*) as Count by Template, Version\n| sort Count desc\n| display Count, Version, Template\n| limit 20",
                "region": "ap-southeast-2",
                "stacked": false,
                "title": "Top error templates",
                "view": "table"
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 29,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '/time/preview21' | fields Properties.AssemblyVersion as Version\n| filter Level = \"Information\"\n| stats count(*) as Count by Version\n| sort by Count\n",
                "region": "ap-southeast-2",
                "stacked": false,
                "title": "Info by version",
                "view": "pie"
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 17,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '/time/preview21' | fields Properties.AssemblyVersion as Version\n| filter Level = \"Error\"\n| stats count(*) as Count by Version\n| sort by Count\n",
                "region": "ap-southeast-2",
                "stacked": false,
                "title": "Errors by version",
                "view": "pie"
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 23,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '/time/preview21' | fields Properties.AssemblyVersion as Version\n| filter Level = \"Warning\"\n| stats count(*) as Count by Version\n| sort by Count\n",
                "region": "ap-southeast-2",
                "stacked": false,
                "title": "Warnings by version",
                "view": "pie"
            }
        },
        {
            "height": 1,
            "width": 24,
            "y": 13,
            "x": 0,
            "type": "text",
            "properties": {
                "markdown": "## Logs "
            }
        },
        {
            "height": 1,
            "width": 24,
            "y": 35,
            "x": 0,
            "type": "text",
            "properties": {
                "markdown": "## ECS "
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 39,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "ECS/ContainerInsights", "MemoryReserved", "ServiceName", "time-preview21-service", "ClusterName", "expensely", { "label": "Reserved" } ],
                    [ ".", "MemoryUtilized", ".", ".", ".", ".", { "label": "Consumed" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "ap-southeast-2",
                "period": 60,
                "stat": "Sum",
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                },
                "title": "Memory"
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 39,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "ECS/ContainerInsights", "CpuReserved", "ServiceName", "time-preview21-service", "ClusterName", "expensely", { "label": "Reserved" } ],
                    [ ".", "CpuUtilized", ".", ".", ".", ".", { "label": "Utilized" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "ap-southeast-2",
                "period": 60,
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                },
                "stat": "Sum",
                "title": "CPU"
            }
        },
        {
            "height": 3,
            "width": 24,
            "y": 36,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "ECS/ContainerInsights", "DeploymentCount", "ServiceName", "time-preview21-service", "ClusterName", "expensely", { "label": "Deployment" } ],
                    [ ".", "DesiredTaskCount", ".", ".", ".", ".", { "label": "Desired" } ],
                    [ ".", "PendingTaskCount", ".", ".", ".", ".", { "label": "Pending" } ],
                    [ ".", "RunningTaskCount", ".", ".", ".", ".", { "label": "Running" } ],
                    [ ".", "TaskSetCount", ".", ".", ".", ".", { "label": "Task" } ]
                ],
                "view": "singleValue",
                "region": "ap-southeast-2",
                "stat": "Average",
                "period": 60,
                "stacked": true,
                "setPeriodToTimeRange": false,
                "liveData": true,
                "sparkline": true,
                "title": "Task count",
                "singleValueFullPrecision": false
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 45,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "ECS/ContainerInsights", "NetworkRxBytes", "ServiceName", "time-preview21-service", "ClusterName", "expensely", { "label": "Receive" } ],
                    [ ".", "NetworkTxBytes", ".", ".", ".", ".", { "label": "Transmit" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "ap-southeast-2",
                "stat": "Sum",
                "period": 60,
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                },
                "title": "Bytes"
            }
        },
        {
            "height": 1,
            "width": 24,
            "y": 12,
            "x": 0,
            "type": "text",
            "properties": {
                "markdown": "# API "
            }
        },
        {
            "height": 3,
            "width": 6,
            "y": 14,
            "x": 6,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/Logs", "IncomingLogEvents", "LogGroupName", "/time/preview21", { "label": "Log Events" } ]
                ],
                "view": "singleValue",
                "region": "ap-southeast-2",
                "period": 300,
                "title": "Incoming",
                "stat": "Average"
            }
        },
        {
            "height": 3,
            "width": 6,
            "y": 14,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/Logs", "IncomingBytes", "LogGroupName", "/time/preview21", { "label": "Bytes" } ]
                ],
                "view": "singleValue",
                "region": "ap-southeast-2",
                "period": 300,
                "title": "Incoming",
                "stat": "Average"
            }
        }
    ]
}
EOF
}

/// Metric filters
resource "aws_cloudwatch_log_metric_filter" "get_health_request_time" {
  name = "GET /health request time"
  pattern = "{ $.MessageTemplate = \"{HostingRequestFinishedLog:l}\" && $.Properties.Method = \"GET\" && $.Properties.Path = \"/health\" }"
  log_group_name = aws_cloudwatch_log_group.api.name

  metric_transformation {
    name = "RequestTime"
    namespace = "Time/${var.environment}/API"
    value = "$.Properties.ElapsedMilliseconds"
    unit = "Milliseconds"
    dimensions = {
      Method: "$.Properties.Method"
      Protocol: "$.Properties.Protocol"
      Path: "$.Properties.Path"
    }
  }
}
resource "aws_cloudwatch_log_metric_filter" "post_record_request_time" {
  name = "POST /v1/Records request time"
  pattern = "{ $.MessageTemplate = \"{HostingRequestFinishedLog:l}\" && $.Properties.Method = \"POST\" && $.Properties.Path = \"/v1/Records\" }"
  log_group_name = aws_cloudwatch_log_group.api.name

  metric_transformation {
    name = "RequestTime"
    namespace = "Time/${var.environment}/API"
    value = "$.Properties.ElapsedMilliseconds"
    unit = "Milliseconds"
    dimensions = {
      Method: "$.Properties.Method"
      Protocol: "$.Properties.Protocol"
      Path: "$.Properties.Path"
    }
  }
}
resource "aws_cloudwatch_log_metric_filter" "get_records_request_time" {
  name = "GET /v1/Records request time"
  pattern = "{ $.MessageTemplate = \"{HostingRequestFinishedLog:l}\" && $.Properties.Method = \"GET\" && $.Properties.Path = \"/v1/Records\" }"
  log_group_name = aws_cloudwatch_log_group.api.name

  metric_transformation {
    name = "RequestTime"
    namespace = "Time/${var.environment}/API"
    value = "$.Properties.ElapsedMilliseconds"
    unit = "Milliseconds"
    dimensions = {
      Method: "$.Properties.Method"
      Protocol: "$.Properties.Protocol"
      Path: "$.Properties.Path"
    }
  }
}
#resource "aws_cloudwatch_log_metric_filter" "put_record_request_time" {
#  name = "PUT /v1/Records/{id} request time"
#  pattern = "{ $.MessageTemplate = \"{HostingRequestFinishedLog:l}\" && $.Properties.Method = \"PUT\" && $.Properties.Path = \"/v1/Records/*\" }"
#  log_group_name = aws_cloudwatch_log_group.api.name
#
#  metric_transformation {
#    name = "RequestTime"
#    namespace = "Time/${var.environment}/API"
#    value = "$.Properties.ElapsedMilliseconds"
#    unit = "Milliseconds"
#    dimensions = {
#      Method: "$.Properties.Method"
#      Protocol: "$.Properties.Protocol"
#      Path: "$.Properties.Path"
#    }
#  }
#}
#resource "aws_cloudwatch_log_metric_filter" "delete_record_request_time" {
#  name = "DELETE /v1/Records/{id} request time"
#  pattern = "{ $.MessageTemplate = \"{HostingRequestFinishedLog:l}\" && $.Properties.Method = \"DELETE\" && $.Properties.Path = \"/v1/Records/*\" }"
#  log_group_name = aws_cloudwatch_log_group.api.name
#
#  metric_transformation {
#    name = "RequestTime"
#    namespace = "Time/${var.environment}/API"
#    value = "$.Properties.ElapsedMilliseconds"
#    unit = "Milliseconds"
#    dimensions = {
#      Method: "$.Properties.Method"
#      Protocol: "$.Properties.Protocol"
#      Path: "$.Properties.Path"
#    }
#  }
#}
#resource "aws_cloudwatch_log_metric_filter" "get_record_request_time" {
#  name = "GET /v1/Records/{id} request time"
#  pattern = "{ $.MessageTemplate = \"{HostingRequestFinishedLog:l}\" && $.Properties.Method = \"GET\" && $.Properties.Path = \"/v1/Records/*\" }"
#  log_group_name = aws_cloudwatch_log_group.api.name
#
#  metric_transformation {
#    name = "RequestTime"
#    namespace = "Time/${var.environment}/API"
#    value = "$.Properties.ElapsedMilliseconds"
#    unit = "Milliseconds"
#    dimensions = {
#      Method: "$.Properties.Method"
#      Protocol: "$.Properties.Protocol"
#      Path: "$.Properties.Path"
#    }
#  }
#}
resource "aws_cloudwatch_log_metric_filter" "get_service_information_request_time" {
  name = "GET /v1/Service/Info request time"
  pattern = "{ $.MessageTemplate = \"{HostingRequestFinishedLog:l}\" && $.Properties.Method = \"GET\" && $.Properties.Path = \"/v1/Service/Info\" }"
  log_group_name = aws_cloudwatch_log_group.api.name

  metric_transformation {
    name = "RequestTime"
    namespace = "Time/${var.environment}/API"
    value = "$.Properties.ElapsedMilliseconds"
    unit = "Milliseconds"
    dimensions = {
      Method: "$.Properties.Method"
      Protocol: "$.Properties.Protocol"
      Path: "$.Properties.Path"
    }
  }
}
