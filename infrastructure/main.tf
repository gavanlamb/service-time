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
  filename = "deploy.yaml"
}
data "template_file" "api_app_spec" {
  template = local.isProduction ? file("./templates/codedeploy.production.yml") : file("./templates/codedeploy.yml")

  vars = {
    application_task_definition = aws_ecs_task_definition.api.arn
    application_container_name = local.api_name
    migrator_lambda_arn = aws_lambda_function.migrator.qualified_arn
    api_tests_lambda_arn = local.isProduction ? null : aws_lambda_function.api_tests[0].qualified_arn
    load_tests_lambda_arn = local.isProduction ? null : aws_lambda_function.load_tests[0].qualified_arn
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
    app_spec_key = "${local.s3_base_path}/code-deploy/deploy.yaml"
    deployment_group_name = aws_codedeploy_deployment_group.api.deployment_group_name
    application_name = aws_codedeploy_app.api.name
  }
}

// Migrator
/// Lambda
resource "aws_lambda_function" "migrator" {
  function_name = local.migrator_name
  role = aws_iam_role.migrator.arn
  description = "Time database migrations"

  package_type = "Image"
  publish = true

  image_uri = "${data.aws_ecr_repository.migrator.repository_url}:${var.build_identifier}"

  memory_size = 10240

  reserved_concurrent_executions = 1

  timeout = 900

  vpc_config {
    security_group_ids = [
      aws_security_group.postgres_client.id,
      data.aws_security_group.external.id]
    subnet_ids = data.aws_subnets.private.ids
  }
  
  environment {
    variables = {
      DOTNET_ENVIRONMENT = var.environment
    }
  }
}

/// Cloudwatch
resource "aws_cloudwatch_log_group" "migrator" {
  name = "/aws/lambda/${aws_lambda_function.migrator.function_name}"
  retention_in_days = 14
}

/// IAM 
resource "aws_iam_role" "migrator" {
  name = local.migrator_name

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
resource "aws_iam_role_policy_attachment" "migrator_vpc" {
  role = aws_iam_role.migrator.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
resource "aws_iam_role_policy_attachment" "migrator_codedeploy" {
  role = aws_iam_role.migrator.name
  policy_arn = aws_iam_policy.codedeploy.arn
}
resource "aws_iam_role_policy_attachment" "migrator_ssm_read" {
  role = aws_iam_role.migrator.name
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

  depends_on = [
    aws_lb_listener_rule.api,
    aws_lb_listener_rule.test
  ]
  lifecycle {
    ignore_changes = [
      desired_count,
      task_definition,
      capacity_provider_strategy,
      load_balancer
    ]
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
        },
        {
          name = "OpenTelemetry__Endpoint",
          value = "http://${local.open_telemetry_name}:4317"
        }
      ]
      portMappings = [
        {
          protocol = "tcp"
          containerPort = 80
        }
      ],
      links = [
        local.open_telemetry_name
      ]
    },{
      name = local.open_telemetry_name
      image = "public.ecr.aws/aws-observability/aws-otel-collector:latest"
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group = aws_cloudwatch_log_group.open_telemetry.name
          awslogs-region = var.region
          awslogs-stream-prefix = "/ecs"
        }
      }
      cpu = 32
      memory = 256

      portMappings = [
        {
          protocol = "tcp"
          hostPort = 0,
          containerPort = 4317
        },
        {
          protocol = "tcp"
          hostPort = 0,
          containerPort = 4318
        }
      ]
      secrets = [
        {
          name = "AOT_CONFIG_CONTENT",
          valueFrom = aws_ssm_parameter.open_telemetry_config.arn
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
    order = 1
  }

  condition {
    host_header {
      values = [
        local.api_url]
    }
  }

  lifecycle {
    ignore_changes = [
      action.0.target_group_arn
    ]
  }
}
resource "aws_lb_listener_rule" "api" {
  listener_arn = data.aws_lb_listener.expensely_https.arn

  action {
    type = "forward"
    target_group_arn = aws_alb_target_group.api_blue.arn
    order = 1
  }

  condition {
    host_header {
      values = [
        local.api_url]
    }
  }

  lifecycle {
    ignore_changes = [
      action.0.target_group_arn
    ]
  }
}
resource "aws_alb_target_group" "api_blue" {
  name = "${local.api_name}-blue"
  port = 80
  protocol = "HTTP"
  vpc_id = data.aws_vpc.vpc.id
  target_type = "instance"
  load_balancing_algorithm_type = "least_outstanding_requests"

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
  load_balancing_algorithm_type = aws_alb_target_group.api_blue.load_balancing_algorithm_type

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
  name = "/${lower(var.application_name)}/${lower(var.environment)}/api"
  retention_in_days = 14
}
resource "aws_cloudwatch_log_group" "open_telemetry" {
  name = "/${lower(var.application_name)}/${lower(var.environment)}/open-telemetry"
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
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
      "xray:*"
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
  assume_role_policy = data.aws_iam_policy_document.api_task.json
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
resource "aws_iam_role_policy_attachment" "api_task_open_telemetry_daemon" {
  role = aws_iam_role.api_task.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}
resource "aws_ssm_parameter" "open_telemetry_config" {
  name  = "/${var.application_name}/${var.environment}/OpenTelemetry/Config"
  type  = "String"
  value = <<EOF
extensions:
  health_check:

receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch/traces:
    timeout: 1s
    send_batch_size: 50
  resourcedetection:
    detectors:
      - env
      - system
      - ecs
      - ec2

exporters:
  awsxray:

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [resourcedetection, batch/traces]
      exporters: [awsxray]

  extensions: [health_check]
EOF
}

//// Execution
resource "aws_iam_role" "api_execution" {
  name = "${local.api_name}-execution-role"
  assume_role_policy = data.aws_iam_policy_document.api_execution.json
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

// API tests
/// lambda
resource "aws_lambda_function" "api_tests" {
  count = local.isProduction ? 0 : 1
  function_name = local.api_tests_name
  role = aws_iam_role.api_tests[0].arn
  description = "Time API tests"

  package_type = "Image"
  publish = true

  image_uri = "${data.aws_ecr_repository.lambda_postman[0].repository_url}:1.0.2432-1"

  memory_size = 10240
  ephemeral_storage {
    size = 4096
  }

  reserved_concurrent_executions = 1

  timeout = 900

  environment {
    variables = {
      S3_BUCKET = var.codedeploy_bucket_name,
      S3_BUCKET_PATH = "${local.s3_base_path}/api-tests",
      POSTMAN_COLLECTION_FILE = "time.postman_collection.json"
      POSTMAN_ENVIRONMENT_FILE = substr(lower(var.environment), 0, 7) == "preview" ? "preview.postman_environment.json" : "${var.environment}.postman_environment.json"
      POSTMAN_VARIABLE_baseUrl = "https://${local.api_url}:8443"
    }
  }
}
/// cloudwatch
resource "aws_cloudwatch_log_group" "api_tests" {
  count = local.isProduction ? 0 : 1
  name = "/aws/lambda/${aws_lambda_function.api_tests[0].function_name}"
  retention_in_days = 14
}
/// IAM
resource "aws_iam_role" "api_tests" {
  count = local.isProduction ? 0 : 1
  name = local.api_tests_name

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
resource "aws_iam_role_policy_attachment" "api_tests_vpc" {
  count = local.isProduction ? 0 : 1
  role = aws_iam_role.api_tests[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
resource "aws_iam_role_policy_attachment" "api_tests_codedeploy" {
  count = local.isProduction ? 0 : 1
  role = aws_iam_role.api_tests[0].name
  policy_arn = aws_iam_policy.codedeploy.arn
}
resource "aws_iam_role_policy_attachment" "api_tests_bucket_upload" {
  count = local.isProduction ? 0 : 1
  role = aws_iam_role.api_tests[0].name
  policy_arn = data.aws_iam_policy.codedeploy_bucket.arn
}

// API tests
/// lambda
resource "aws_lambda_function" "load_tests" {
  count = local.isProduction ? 0 : 1
  function_name = local.load_tests_name
  role = aws_iam_role.load_tests[0].arn
  description = "Time Load tests"

  package_type = "Image"
  publish = true

  image_uri = "${data.aws_ecr_repository.load_tests[0].repository_url}:1.0.2403-1"

  memory_size = 10240

  ephemeral_storage {
    size = 4096
  }
  
  reserved_concurrent_executions = 1

  timeout = 900

  environment {
    variables = {
      S3_BUCKET = var.codedeploy_bucket_name,
      S3_BUCKET_PATH = "${local.s3_base_path}/load-tests",
      JMETER_LOADTEST_FILE = "load.jmx",
      JMETER_USERS_FILE = "users.csv"
    }
  }
}
/// cloudwatch
resource "aws_cloudwatch_log_group" "load_tests" {
  count = local.isProduction ? 0 : 1
  name = "/aws/lambda/${aws_lambda_function.load_tests[0].function_name}"
  retention_in_days = 14
}
/// IAM
resource "aws_iam_role" "load_tests" {
  count = local.isProduction ? 0 : 1
  name = local.load_tests_name

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
resource "aws_iam_role_policy_attachment" "load_tests_vpc" {
  count = local.isProduction ? 0 : 1
  role = aws_iam_role.load_tests[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
resource "aws_iam_role_policy_attachment" "load_tests_codedeploy" {
  count = local.isProduction ? 0 : 1
  role = aws_iam_role.load_tests[0].name
  policy_arn = aws_iam_policy.codedeploy.arn
}
resource "aws_iam_role_policy_attachment" "load_tests_bucket_upload" {
  count = local.isProduction ? 0 : 1
  role = aws_iam_role.load_tests[0].name
  policy_arn = data.aws_iam_policy.codedeploy_bucket.arn
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
  depends_on = [aws_cloudwatch_log_group.rds]
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

resource "aws_cloudwatch_log_group" "rds" {
  name = "/aws/rds/cluster/${local.rds_name}/postgresql"
  retention_in_days = 14
}

// Cloudwatch
/// Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = local.api_name
  dashboard_body = local.isProduction ? local.productionDashboard : local.defaultDashboard
}

/// Metric filters
resource "aws_cloudwatch_log_metric_filter" "request_time" {
  name = "Request time"
  pattern = "{ $.MessageTemplate = \"{HostingRequestFinishedLog:l}\" }"
  log_group_name = aws_cloudwatch_log_group.api.name

  metric_transformation {
    name = "RequestTime"
    namespace = "${var.application_name}/${var.environment}/API"
    value = "$.Properties.ElapsedMilliseconds"
    unit = "Milliseconds"
    dimensions = {
      Method: "$.Properties.Method"
      Protocol: "$.Properties.Protocol"
      Path: "$.Properties.RoutePattern"
    }
  }
}
