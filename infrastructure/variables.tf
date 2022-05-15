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
  
  productionDashboard = <<EOF
{
    "widgets": [
        {
            "height": 6,
            "width": 6,
            "y": 0,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '${aws_cloudwatch_log_group.api.name}' | fields Properties.StatusCode as Code\n| filter MessageTemplate = \"HTTP {RequestMethod} {RequestPath} responded {StatusCode} in {Elapsed:0.0000} ms\"\n| filter Properties.RequestPath != \"/health\"\n| stats count(*) as Count by Code\n| sort by Code\n",
                "region": "${var.region}",
                "stacked": false,
                "title": "Response codes",
                "view": "pie"
            }
        },
        {
            "height": 6,
            "width": 18,
            "y": 0,
            "x": 6,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "${aws_cloudwatch_log_metric_filter.request_time.metric_transformation[0].namespace}", "RequestTime", "Path", "/v1/Records/{id:long}", "Method", "PUT", "Protocol", "HTTP/1.1" ],
                    [ "...", "/v1/Records", ".", "POST", ".", "." ],
                    [ "...", "/v1/Records/{id:long}", ".", "GET", ".", "." ],
                    [ "...", "/v1/Service/Info", ".", ".", ".", "." ],
                    [ "...", "/v1/Records", ".", ".", ".", "." ],
                    [ "...", "/v1/Records/{id:long}", ".", "DELETE", ".", "." ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "stat": "Average",
                "period": 60,
                "title": "Responce times",
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
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
                "query": "SOURCE '${aws_cloudwatch_log_group.api.name}' | fields MessageTemplate as Template, Level\n| stats count(*) as Count by Template, Level\n| sort Count desc\n| display Count, Level, Template\n| limit 50",
                "region": "${var.region}",
                "stacked": false,
                "title": "Top log templates",
                "view": "table"
            }
        },
        {
            "height": 3,
            "width": 6,
            "y": 12,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/Logs", "IncomingBytes", "LogGroupName", "${aws_cloudwatch_log_group.api.name}", { "label": "Bytes" } ]
                ],
                "view": "singleValue",
                "region": "${var.region}",
                "period": 300,
                "title": "Incoming",
                "stat": "Average",
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                }
            }
        },
        {
            "height": 3,
            "width": 6,
            "y": 12,
            "x": 6,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/Logs", "IncomingLogEvents", "LogGroupName", "${aws_cloudwatch_log_group.api.name}", { "label": "Log Events" } ]
                ],
                "view": "singleValue",
                "region": "${var.region}",
                "period": 300,
                "title": "Incoming",
                "stat": "Average",
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                }
            }
        },
        {
            "height": 1,
            "width": 24,
            "y": 15,
            "x": 0,
            "type": "text",
            "properties": {
                "markdown": "# API "
            }
        },
        {
            "height": 1,
            "width": 24,
            "y": 16,
            "x": 0,
            "type": "text",
            "properties": {
                "markdown": "## Logs "
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 17,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '${aws_cloudwatch_log_group.api.name}' | fields Properties.AssemblyVersion as Version\n| filter Level = \"Error\"\n| stats count(*) as Count by Version\n| sort by Version desc, Count\n",
                "region": "${var.region}",
                "stacked": false,
                "title": "Errors by version",
                "view": "pie"
            }
        },
        {
            "height": 6,
            "width": 18,
            "y": 17,
            "x": 6,
            "type": "log",
            "properties": {
                "query": "SOURCE '${aws_cloudwatch_log_group.api.name}' | fields Properties.AssemblyVersion as Version, MessageTemplate as Template\n| filter Level = \"Error\"\n| stats count(*) as Count by Template, Version\n| sort Count desc, Version desc, Template\n| display Count, Version, Template\n| limit 20",
                "region": "${var.region}",
                "stacked": false,
                "title": "Top error templates",
                "view": "table"
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 23,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '${aws_cloudwatch_log_group.api.name}' | fields Properties.AssemblyVersion as Version\n| filter Level = \"Warning\"\n| stats count(*) as Count by Version\n| sort by Version desc, Count\n",
                "region": "${var.region}",
                "stacked": false,
                "title": "Warnings by version",
                "view": "pie"
            }
        },
        {
            "height": 6,
            "width": 18,
            "y": 23,
            "x": 6,
            "type": "log",
            "properties": {
                "query": "SOURCE '${aws_cloudwatch_log_group.api.name}' | fields Properties.AssemblyVersion as Version, MessageTemplate as Template\n| filter Level = \"Warning\"\n| stats count(*) as Count by Template, Version\n| sort Count desc, Version desc, Template\n| display Count, Version, Template\n| limit 20",
                "region": "${var.region}",
                "stacked": false,
                "title": "Top warning templates",
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
                "query": "SOURCE '${aws_cloudwatch_log_group.api.name}' | fields Properties.AssemblyVersion as Version\n| filter Level = \"Information\"\n| stats count(*) as Count by Version\n| sort by Version desc, Count\n",
                "region": "${var.region}",
                "stacked": false,
                "title": "Info by version",
                "view": "pie"
            }
        },        
        {
            "height": 6,
            "width": 18,
            "y": 29,
            "x": 6,
            "type": "log",
            "properties": {
                "query": "SOURCE '${aws_cloudwatch_log_group.api.name}' | fields Properties.AssemblyVersion as Version, MessageTemplate as Template\n| filter Level = \"Information\"\n| stats count(*) as Count by Template, Version\n| sort Count desc, Version desc, Template\n| display Count, Version, Template\n| limit 20",
                "region": "${var.region}",
                "stacked": false,
                "title": "Top information templates",
                "view": "table"
            }
        },
        {
            "height": 1,
            "width": 24,
            "y": 35,
            "x": 0,
            "type": "text",
            "properties": {
                "markdown": "## ALB"
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 36,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/ApplicationELB", "RequestCountPerTarget", "TargetGroup", "${aws_alb_target_group.api_blue.arn_suffix}", "LoadBalancer", "${data.aws_lb.expensely.arn_suffix}", { "id": "m1", "label": "Blue" } ],
                    [ "AWS/ApplicationELB", "RequestCountPerTarget", "TargetGroup", "${aws_alb_target_group.api_green.arn_suffix}", "LoadBalancer", "${data.aws_lb.expensely.arn_suffix}", { "id": "m2", "label": "Green", "color": "#2ca02c" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "stat": "SampleCount",
                "period": 60,
                "title": "Total target requests",
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 36,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/ApplicationELB", "TargetResponseTime", "TargetGroup", "${aws_alb_target_group.api_blue.arn_suffix}", "LoadBalancer", "${data.aws_lb.expensely.arn_suffix}", { "id": "m1", "label": "Blue" } ],
                    [ "AWS/ApplicationELB", "TargetResponseTime", "TargetGroup", "${aws_alb_target_group.api_green.arn_suffix}", "LoadBalancer", "${data.aws_lb.expensely.arn_suffix}", { "id": "m2", "label": "Green", "color": "#2ca02c" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "stat": "Average",
                "period": 60,
                "title": "Target response time",
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 42,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", "${aws_alb_target_group.api_blue.arn_suffix}", "LoadBalancer", "${data.aws_lb.expensely.arn_suffix}", { "id": "m1", "color": "#1f77b4", "label": "Healthy host count" } ],
                    [ "AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", "${aws_alb_target_group.api_green.arn_suffix}", "LoadBalancer", "${data.aws_lb.expensely.arn_suffix}", { "id": "m2", "color": "#2ca02c", "label": "Healthy host count" } ],
                    [ "AWS/ApplicationELB", "UnHealthyHostCount", "TargetGroup", "${aws_alb_target_group.api_blue.arn_suffix}", "LoadBalancer", "${data.aws_lb.expensely.arn_suffix}", { "id": "m3", "color": "#17becf", "label": "Unhealthy host count" } ],
                    [ "AWS/ApplicationELB", "UnHealthyHostCount", "TargetGroup", "${aws_alb_target_group.api_green.arn_suffix}", "LoadBalancer", "${data.aws_lb.expensely.arn_suffix}", { "id": "m4", "color": "#bcbd22", "label": "Unhealthy host count" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "stat": "Average",
                "period": 60,
                "title": "Host count",
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 42,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "TargetGroup", "${aws_alb_target_group.api_blue.arn_suffix}", "LoadBalancer", "${data.aws_lb.expensely.arn_suffix}", { "id": "m1", "label": "4xx", "color": "#1f77b4" } ],
                    [ "AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "TargetGroup", "${aws_alb_target_group.api_green.arn_suffix}", "LoadBalancer", "${data.aws_lb.expensely.arn_suffix}", { "id": "m2", "label": "4xx", "color": "#2ca02c" } ],
                    [ "AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "TargetGroup", "${aws_alb_target_group.api_blue.arn_suffix}", "LoadBalancer", "${data.aws_lb.expensely.arn_suffix}", { "id": "m3", "label": "2xx", "color": "#17becf" } ],
                    [ "AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "TargetGroup", "${aws_alb_target_group.api_green.arn_suffix}", "LoadBalancer", "${data.aws_lb.expensely.arn_suffix}", { "id": "m4", "label": "2xx", "color": "#bcbd22" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "stat": "Sum",
                "period": 60,
                "title": "Response code",
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                }
            }
        },
        {
            "height": 1,
            "width": 24,
            "y": 48,
            "x": 0,
            "type": "text",
            "properties": {
                "markdown": "## ECS "
            }
        },
        {
            "height": 3,
            "width": 24,
            "y": 49,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "ECS/ContainerInsights", "DeploymentCount", "ServiceName", "${aws_ecs_service.api.name}", "ClusterName", "expensely", { "label": "Deployment" } ],
                    [ ".", "DesiredTaskCount", ".", ".", ".", ".", { "label": "Desired" } ],
                    [ ".", "PendingTaskCount", ".", ".", ".", ".", { "label": "Pending" } ],
                    [ ".", "RunningTaskCount", ".", ".", ".", ".", { "label": "Running" } ],
                    [ ".", "TaskSetCount", ".", ".", ".", ".", { "label": "Task" } ]
                ],
                "view": "singleValue",
                "region": "${var.region}",
                "stat": "Average",
                "period": 60,
                "stacked": true,
                "setPeriodToTimeRange": false,
                "liveData": true,
                "sparkline": true,
                "title": "Task count",
                "singleValueFullPrecision": false,
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 52,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "ECS/ContainerInsights", "CpuReserved", "ServiceName", "${aws_ecs_service.api.name}", "ClusterName", "expensely", { "label": "Reserved" } ],
                    [ ".", "CpuUtilized", ".", ".", ".", ".", { "label": "Utilized" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "period": 60,
                "stat": "Sum",
                "title": "CPU",
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 52,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "ECS/ContainerInsights", "MemoryReserved", "ServiceName", "${aws_ecs_service.api.name}", "ClusterName", "expensely", { "label": "Reserved" } ],
                    [ ".", "MemoryUtilized", ".", ".", ".", ".", { "label": "Consumed" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "period": 60,
                "stat": "Sum",
                "title": "Memory",
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 64,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "ECS/ContainerInsights", "NetworkRxBytes", "ServiceName", "${aws_ecs_service.api.name}", "ClusterName", "expensely", { "label": "Receive" } ],
                    [ ".", "NetworkTxBytes", ".", ".", ".", ".", { "label": "Transmit" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "stat": "Sum",
                "period": 60,
                "title": "Bytes",
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                }
            }
        },
        {
            "height": 1,
            "width": 24,
            "y": 70,
            "x": 0,
            "type": "text",
            "properties": {
                "markdown": "## Health "
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 71,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '${aws_cloudwatch_log_group.api.name}' | fields Properties.StatusCode\n| filter MessageTemplate = \"HTTP {RequestMethod} {RequestPath} responded {StatusCode} in {Elapsed:0.0000} ms\"\n| filter Properties.RequestPath = \"/health\"\n| stats count(*) as Count by Properties.StatusCode\n| sort by Code\n",
                "region": "${var.region}",
                "stacked": false,
                "view": "pie",
                "title": "Response codes"
            }
        },
        {
            "height": 6,
            "width": 18,
            "y": 71,
            "x": 6,
            "type": "metric",
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "${aws_cloudwatch_log_metric_filter.request_time.metric_transformation[0].namespace}", "RequestTime", "Path", "/health", "Method", "GET", "Protocol", "HTTP/1.1" ]
                ],
                "region": "${var.region}",
                "period": 300,
                "liveData": true,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "showUnits": false
                    },
                    "right": {
                        "min": 0,
                        "showUnits": false
                    }
                },
                "legend": {
                    "position": "hidden"
                },
                "title": "Request time"
            }
        },
        {
            "height": 1,
            "width": 24,
            "y": 77,
            "x": 0,
            "type": "text",
            "properties": {
                "markdown": "# RDS "
            }
        },
        {
            "height": 6,
            "width": 24,
            "y": 78,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '/aws/rds/cluster/${local.rds_name}/postgresql' | fields @message\n| sort by @timestamp desc",
                "region": "${var.region}",
                "stacked": false,
                "title": "Logs",
                "view": "table"
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 58,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "CPUUtilization", "DBClusterIdentifier", "${module.postgres.rds_cluster_id}", { "label": "Utilization" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "stat": "Average",
                "period": 60,
                "title": "CPU",
                "legend": {
                    "position": "bottom"
                },
                "setPeriodToTimeRange": true,
                "liveData": true,
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 58,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "FreeableMemory", "DBClusterIdentifier", "${module.postgres.rds_cluster_id}", { "label": "Freeable" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "period": 60,
                "stat": "Average",
                "title": "Memory",
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                },
                "liveData": true
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 64,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "FreeLocalStorage", "DBClusterIdentifier", "${module.postgres.rds_cluster_id}", { "label": "Free Local" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "stat": "Average",
                "period": 60,
                "title": "Storage",
                "liveData": true,
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 90,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "ReadIOPS", "DBClusterIdentifier", "${module.postgres.rds_cluster_id}", { "yAxis": "right", "label": "Read" } ],
                    [ ".", "WriteIOPS", ".", ".", { "label": "Write" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
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
                "liveData": true
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 96,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "DatabaseConnections", "DBClusterIdentifier", "${module.postgres.rds_cluster_id}", { "label": "Connections" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "stat": "Average",
                "period": 60,
                "title": "Connections",
                "yAxis": {
                    "left": {
                        "min": 0,
                        "label": ""
                    },
                    "right": {
                        "min": 0,
                        "label": ""
                    }
                },
                "liveData": true,
                "legend": {
                    "position": "hidden"
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 90,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "Deadlocks", "DBClusterIdentifier", "${module.postgres.rds_cluster_id}" ]
                ],
                "view": "timeSeries",
                "stacked": true,
                "region": "${var.region}",
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                },
                "legend": {
                    "position": "hidden"
                },
                "title": "Deadlocks",
                "period": 60,
                "liveData": true,
                "stat": "Average"
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 102,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "BufferCacheHitRatio", "DBClusterIdentifier", "${module.postgres.rds_cluster_id}", { "label": "Cache Hit Ratio" } ]
                ],
                "view": "timeSeries",
                "region": "${var.region}",
                "stacked": false,
                "period": 60,
                "stat": "Average",
                "title": "Buffer",
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 96,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "ServerlessDatabaseCapacity", "DBClusterIdentifier", "${module.postgres.rds_cluster_id}", { "label": "ServerlessDatabaseCapacity" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "stat": "Average",
                "period": 60,
                "title": "Capacity",
                "legend": {
                    "position": "hidden"
                },
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                },
                "liveData": true
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 102,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "AuroraReplicaLag", "DBClusterIdentifier", "${module.postgres.rds_cluster_id}" ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "title": "Replica lag",
                "stat": "Average",
                "period": 60,
                "liveData": true,
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                }
            }
        },
        {
            "height": 1,
            "width": 24,
            "y": 108,
            "x": 0,
            "type": "text",
            "properties": {
                "markdown": "# Migrator "
            }
        },
        {
            "height": 6,
            "width": 24,
            "y": 109,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '${aws_cloudwatch_log_group.migrator.name}' | fields MessageTemplate as Template, Level\n| filter isPresent(Template)\n| stats count(*) as Count by Template, Level\n| sort Count desc\n| display Count, Level, Template\n| limit 50",
                "region": "${var.region}",
                "stacked": false,
                "title": "Top log templates",
                "view": "table"
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 115,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/Lambda", "Errors", "FunctionName", "${aws_lambda_function.migrator.function_name}" ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "title": "Errors",
                "stat": "Sum",
                "period": 60,
                "yAxis": {
                    "left": {
                        "showUnits": false,
                        "min": 0
                    },
                    "right": {
                        "showUnits": false,
                        "min": 0
                    }
                },
                "legend": {
                    "position": "hidden"
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 115,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/Lambda", "Invocations", "FunctionName", "${aws_lambda_function.migrator.function_name}" ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "title": "Invocations",
                "stat": "Sum",
                "period": 60,
                "yAxis": {
                    "left": {
                        "showUnits": false,
                        "min": 0
                    },
                    "right": {
                        "showUnits": false,
                        "min": 0
                    }
                },
                "legend": {
                    "position": "hidden"
                }
            }
        },
        {
            "height": 6,
            "width": 24,
            "y": 121,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/Lambda", "Duration", "FunctionName", "${aws_lambda_function.migrator.function_name}" ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "title": "Duration",
                "stat": "Sum",
                "period": 60,
                "yAxis": {
                    "left": {
                        "showUnits": false,
                        "min": 0
                    },
                    "right": {
                        "showUnits": false,
                        "min": 0
                    }
                },
                "legend": {
                    "position": "hidden"
                }
            }
        }
    ]
}
EOF
  defaultDashboard = <<EOF
{
    "widgets": [
        {
            "height": 6,
            "width": 6,
            "y": 0,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '${aws_cloudwatch_log_group.api.name}' | fields Properties.StatusCode as Code\n| filter MessageTemplate = \"HTTP {RequestMethod} {RequestPath} responded {StatusCode} in {Elapsed:0.0000} ms\"\n| filter Properties.RequestPath != \"/health\"\n| stats count(*) as Count by Code\n| sort by Code\n",
                "region": "${var.region}",
                "stacked": false,
                "title": "Response codes",
                "view": "pie"
            }
        },
        {
            "height": 6,
            "width": 18,
            "y": 0,
            "x": 6,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "${aws_cloudwatch_log_metric_filter.request_time.metric_transformation[0].namespace}", "RequestTime", "Path", "/v1/Records/{id:long}", "Method", "PUT", "Protocol", "HTTP/1.1" ],
                    [ "...", "/v1/Records", ".", "POST", ".", "." ],
                    [ "...", "/v1/Records/{id:long}", ".", "GET", ".", "." ],
                    [ "...", "/v1/Service/Info", ".", ".", ".", "." ],
                    [ "...", "/v1/Records", ".", ".", ".", "." ],
                    [ "...", "/v1/Records/{id:long}", ".", "DELETE", ".", "." ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "stat": "Average",
                "period": 60,
                "title": "Responce times",
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
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
                "query": "SOURCE '${aws_cloudwatch_log_group.api.name}' | fields MessageTemplate as Template, Level\n| stats count(*) as Count by Template, Level\n| sort Count desc\n| display Count, Level, Template\n| limit 50",
                "region": "${var.region}",
                "stacked": false,
                "title": "Top log templates",
                "view": "table"
            }
        },
        {
            "height": 3,
            "width": 6,
            "y": 12,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/Logs", "IncomingBytes", "LogGroupName", "${aws_cloudwatch_log_group.api.name}", { "label": "Bytes" } ]
                ],
                "view": "singleValue",
                "region": "${var.region}",
                "period": 300,
                "title": "Incoming",
                "stat": "Average",
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                }
            }
        },
        {
            "height": 3,
            "width": 6,
            "y": 12,
            "x": 6,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/Logs", "IncomingLogEvents", "LogGroupName", "${aws_cloudwatch_log_group.api.name}", { "label": "Log Events" } ]
                ],
                "view": "singleValue",
                "region": "${var.region}",
                "period": 300,
                "title": "Incoming",
                "stat": "Average",
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                }
            }
        },
        {
            "height": 1,
            "width": 24,
            "y": 15,
            "x": 0,
            "type": "text",
            "properties": {
                "markdown": "# API "
            }
        },
        {
            "height": 1,
            "width": 24,
            "y": 16,
            "x": 0,
            "type": "text",
            "properties": {
                "markdown": "## Logs "
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 17,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '${aws_cloudwatch_log_group.api.name}' | fields Properties.AssemblyVersion as Version\n| filter Level = \"Error\"\n| stats count(*) as Count by Version\n| sort by Version desc, Count\n",
                "region": "${var.region}",
                "stacked": false,
                "title": "Errors by version",
                "view": "pie"
            }
        },
        {
            "height": 6,
            "width": 18,
            "y": 17,
            "x": 6,
            "type": "log",
            "properties": {
                "query": "SOURCE '${aws_cloudwatch_log_group.api.name}' | fields Properties.AssemblyVersion as Version, MessageTemplate as Template\n| filter Level = \"Error\"\n| stats count(*) as Count by Template, Version\n| sort Count desc, Version desc, Template\n| display Count, Version, Template\n| limit 20",
                "region": "${var.region}",
                "stacked": false,
                "title": "Top error templates",
                "view": "table"
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 23,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '${aws_cloudwatch_log_group.api.name}' | fields Properties.AssemblyVersion as Version\n| filter Level = \"Warning\"\n| stats count(*) as Count by Version\n| sort by Version desc, Count\n",
                "region": "${var.region}",
                "stacked": false,
                "title": "Warnings by version",
                "view": "pie"
            }
        },
        {
            "height": 6,
            "width": 18,
            "y": 23,
            "x": 6,
            "type": "log",
            "properties": {
                "query": "SOURCE '${aws_cloudwatch_log_group.api.name}' | fields Properties.AssemblyVersion as Version, MessageTemplate as Template\n| filter Level = \"Warning\"\n| stats count(*) as Count by Template, Version\n| sort Count desc, Version desc, Template\n| display Count, Version, Template\n| limit 20",
                "region": "${var.region}",
                "stacked": false,
                "title": "Top warning templates",
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
                "query": "SOURCE '${aws_cloudwatch_log_group.api.name}' | fields Properties.AssemblyVersion as Version\n| filter Level = \"Information\"\n| stats count(*) as Count by Version\n| sort by Version desc, Count\n",
                "region": "${var.region}",
                "stacked": false,
                "title": "Info by version",
                "view": "pie"
            }
        },        
        {
            "height": 6,
            "width": 18,
            "y": 29,
            "x": 6,
            "type": "log",
            "properties": {
                "query": "SOURCE '${aws_cloudwatch_log_group.api.name}' | fields Properties.AssemblyVersion as Version, MessageTemplate as Template\n| filter Level = \"Information\"\n| stats count(*) as Count by Template, Version\n| sort Count desc, Version desc, Template\n| display Count, Version, Template\n| limit 20",
                "region": "${var.region}",
                "stacked": false,
                "title": "Top information templates",
                "view": "table"
            }
        },
        {
            "height": 1,
            "width": 24,
            "y": 35,
            "x": 0,
            "type": "text",
            "properties": {
                "markdown": "## ALB"
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 36,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/ApplicationELB", "RequestCountPerTarget", "TargetGroup", "${aws_alb_target_group.api_blue.arn_suffix}", "LoadBalancer", "${data.aws_lb.expensely.arn_suffix}", { "id": "m1", "label": "Blue" } ],
                    [ "AWS/ApplicationELB", "RequestCountPerTarget", "TargetGroup", "${aws_alb_target_group.api_green.arn_suffix}", "LoadBalancer", "${data.aws_lb.expensely.arn_suffix}", { "id": "m2", "label": "Green", "color": "#2ca02c" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "stat": "SampleCount",
                "period": 60,
                "title": "Total target requests",
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 36,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/ApplicationELB", "TargetResponseTime", "TargetGroup", "${aws_alb_target_group.api_blue.arn_suffix}", "LoadBalancer", "${data.aws_lb.expensely.arn_suffix}", { "id": "m1", "label": "Blue" } ],
                    [ "AWS/ApplicationELB", "TargetResponseTime", "TargetGroup", "${aws_alb_target_group.api_green.arn_suffix}", "LoadBalancer", "${data.aws_lb.expensely.arn_suffix}", { "id": "m2", "label": "Green", "color": "#2ca02c" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "stat": "Average",
                "period": 60,
                "title": "Target response time",
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 42,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", "${aws_alb_target_group.api_blue.arn_suffix}", "LoadBalancer", "${data.aws_lb.expensely.arn_suffix}", { "id": "m1", "color": "#1f77b4", "label": "Healthy host count" } ],
                    [ "AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", "${aws_alb_target_group.api_green.arn_suffix}", "LoadBalancer", "${data.aws_lb.expensely.arn_suffix}", { "id": "m2", "color": "#2ca02c", "label": "Healthy host count" } ],
                    [ "AWS/ApplicationELB", "UnHealthyHostCount", "TargetGroup", "${aws_alb_target_group.api_blue.arn_suffix}", "LoadBalancer", "${data.aws_lb.expensely.arn_suffix}", { "id": "m3", "color": "#17becf", "label": "Unhealthy host count" } ],
                    [ "AWS/ApplicationELB", "UnHealthyHostCount", "TargetGroup", "${aws_alb_target_group.api_green.arn_suffix}", "LoadBalancer", "${data.aws_lb.expensely.arn_suffix}", { "id": "m4", "color": "#bcbd22", "label": "Unhealthy host count" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "stat": "Average",
                "period": 60,
                "title": "Host count",
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 42,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "TargetGroup", "${aws_alb_target_group.api_blue.arn_suffix}", "LoadBalancer", "${data.aws_lb.expensely.arn_suffix}", { "id": "m1", "label": "4xx", "color": "#1f77b4" } ],
                    [ "AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "TargetGroup", "${aws_alb_target_group.api_green.arn_suffix}", "LoadBalancer", "${data.aws_lb.expensely.arn_suffix}", { "id": "m2", "label": "4xx", "color": "#2ca02c" } ],
                    [ "AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "TargetGroup", "${aws_alb_target_group.api_blue.arn_suffix}", "LoadBalancer", "${data.aws_lb.expensely.arn_suffix}", { "id": "m3", "label": "2xx", "color": "#17becf" } ],
                    [ "AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "TargetGroup", "${aws_alb_target_group.api_green.arn_suffix}", "LoadBalancer", "${data.aws_lb.expensely.arn_suffix}", { "id": "m4", "label": "2xx", "color": "#bcbd22" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "stat": "Sum",
                "period": 60,
                "title": "Response code",
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                }
            }
        },
        {
            "height": 1,
            "width": 24,
            "y": 48,
            "x": 0,
            "type": "text",
            "properties": {
                "markdown": "## ECS "
            }
        },
        {
            "height": 3,
            "width": 24,
            "y": 49,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "ECS/ContainerInsights", "DeploymentCount", "ServiceName", "${aws_ecs_service.api.name}", "ClusterName", "expensely", { "label": "Deployment" } ],
                    [ ".", "DesiredTaskCount", ".", ".", ".", ".", { "label": "Desired" } ],
                    [ ".", "PendingTaskCount", ".", ".", ".", ".", { "label": "Pending" } ],
                    [ ".", "RunningTaskCount", ".", ".", ".", ".", { "label": "Running" } ],
                    [ ".", "TaskSetCount", ".", ".", ".", ".", { "label": "Task" } ]
                ],
                "view": "singleValue",
                "region": "${var.region}",
                "stat": "Average",
                "period": 60,
                "stacked": true,
                "setPeriodToTimeRange": false,
                "liveData": true,
                "sparkline": true,
                "title": "Task count",
                "singleValueFullPrecision": false,
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 52,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "ECS/ContainerInsights", "CpuReserved", "ServiceName", "${aws_ecs_service.api.name}", "ClusterName", "expensely", { "label": "Reserved" } ],
                    [ ".", "CpuUtilized", ".", ".", ".", ".", { "label": "Utilized" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "period": 60,
                "stat": "Sum",
                "title": "CPU",
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 52,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "ECS/ContainerInsights", "MemoryReserved", "ServiceName", "${aws_ecs_service.api.name}", "ClusterName", "expensely", { "label": "Reserved" } ],
                    [ ".", "MemoryUtilized", ".", ".", ".", ".", { "label": "Consumed" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "period": 60,
                "stat": "Sum",
                "title": "Memory",
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 64,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "ECS/ContainerInsights", "NetworkRxBytes", "ServiceName", "${aws_ecs_service.api.name}", "ClusterName", "expensely", { "label": "Receive" } ],
                    [ ".", "NetworkTxBytes", ".", ".", ".", ".", { "label": "Transmit" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "stat": "Sum",
                "period": 60,
                "title": "Bytes",
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                }
            }
        },
        {
            "height": 1,
            "width": 24,
            "y": 70,
            "x": 0,
            "type": "text",
            "properties": {
                "markdown": "## Health "
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 71,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '${aws_cloudwatch_log_group.api.name}' | fields Properties.StatusCode\n| filter MessageTemplate = \"HTTP {RequestMethod} {RequestPath} responded {StatusCode} in {Elapsed:0.0000} ms\"\n| filter Properties.RequestPath = \"/health\"\n| stats count(*) as Count by Properties.StatusCode\n| sort by Code\n",
                "region": "${var.region}",
                "stacked": false,
                "view": "pie",
                "title": "Response codes"
            }
        },
        {
            "height": 6,
            "width": 18,
            "y": 71,
            "x": 6,
            "type": "metric",
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "${aws_cloudwatch_log_metric_filter.request_time.metric_transformation[0].namespace}", "RequestTime", "Path", "/health", "Method", "GET", "Protocol", "HTTP/1.1" ]
                ],
                "region": "${var.region}",
                "period": 300,
                "liveData": true,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "showUnits": false
                    },
                    "right": {
                        "min": 0,
                        "showUnits": false
                    }
                },
                "legend": {
                    "position": "hidden"
                },
                "title": "Request time"
            }
        },
        {
            "height": 1,
            "width": 24,
            "y": 77,
            "x": 0,
            "type": "text",
            "properties": {
                "markdown": "# RDS "
            }
        },
        {
            "height": 6,
            "width": 24,
            "y": 78,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '/aws/rds/cluster/${local.rds_name}/postgresql' | fields @message\n| sort by @timestamp desc",
                "region": "${var.region}",
                "stacked": false,
                "title": "Logs",
                "view": "table"
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 58,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "CPUUtilization", "DBClusterIdentifier", "${module.postgres.rds_cluster_id}", { "label": "Utilization" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "stat": "Average",
                "period": 60,
                "title": "CPU",
                "legend": {
                    "position": "bottom"
                },
                "setPeriodToTimeRange": true,
                "liveData": true,
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 58,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "FreeableMemory", "DBClusterIdentifier", "${module.postgres.rds_cluster_id}", { "label": "Freeable" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "period": 60,
                "stat": "Average",
                "title": "Memory",
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                },
                "liveData": true
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 64,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "FreeLocalStorage", "DBClusterIdentifier", "${module.postgres.rds_cluster_id}", { "label": "Free Local" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "stat": "Average",
                "period": 60,
                "title": "Storage",
                "liveData": true,
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 90,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "ReadIOPS", "DBClusterIdentifier", "${module.postgres.rds_cluster_id}", { "yAxis": "right", "label": "Read" } ],
                    [ ".", "WriteIOPS", ".", ".", { "label": "Write" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
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
                "liveData": true
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 96,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "DatabaseConnections", "DBClusterIdentifier", "${module.postgres.rds_cluster_id}", { "label": "Connections" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "stat": "Average",
                "period": 60,
                "title": "Connections",
                "yAxis": {
                    "left": {
                        "min": 0,
                        "label": ""
                    },
                    "right": {
                        "min": 0,
                        "label": ""
                    }
                },
                "liveData": true,
                "legend": {
                    "position": "hidden"
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 90,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "Deadlocks", "DBClusterIdentifier", "${module.postgres.rds_cluster_id}" ]
                ],
                "view": "timeSeries",
                "stacked": true,
                "region": "${var.region}",
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                },
                "legend": {
                    "position": "hidden"
                },
                "title": "Deadlocks",
                "period": 60,
                "liveData": true,
                "stat": "Average"
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 102,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "BufferCacheHitRatio", "DBClusterIdentifier", "${module.postgres.rds_cluster_id}", { "label": "Cache Hit Ratio" } ]
                ],
                "view": "timeSeries",
                "region": "${var.region}",
                "stacked": false,
                "period": 60,
                "stat": "Average",
                "title": "Buffer",
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 96,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "ServerlessDatabaseCapacity", "DBClusterIdentifier", "${module.postgres.rds_cluster_id}", { "label": "ServerlessDatabaseCapacity" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "stat": "Average",
                "period": 60,
                "title": "Capacity",
                "legend": {
                    "position": "hidden"
                },
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                },
                "liveData": true
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 102,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "AuroraReplicaLag", "DBClusterIdentifier", "${module.postgres.rds_cluster_id}" ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "title": "Replica lag",
                "stat": "Average",
                "period": 60,
                "liveData": true,
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                }
            }
        },
        {
            "height": 1,
            "width": 24,
            "y": 108,
            "x": 0,
            "type": "text",
            "properties": {
                "markdown": "# Migrator "
            }
        },
        {
            "height": 6,
            "width": 24,
            "y": 109,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '${aws_cloudwatch_log_group.migrator.name}' | fields MessageTemplate as Template, Level\n| filter isPresent(Template)\n| stats count(*) as Count by Template, Level\n| sort Count desc\n| display Count, Level, Template\n| limit 50",
                "region": "${var.region}",
                "stacked": false,
                "title": "Top log templates",
                "view": "table"
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 115,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/Lambda", "Errors", "FunctionName", "${aws_lambda_function.migrator.function_name}" ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "title": "Errors",
                "stat": "Sum",
                "period": 60,
                "yAxis": {
                    "left": {
                        "showUnits": false,
                        "min": 0
                    },
                    "right": {
                        "showUnits": false,
                        "min": 0
                    }
                },
                "legend": {
                    "position": "hidden"
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 115,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/Lambda", "Invocations", "FunctionName", "${aws_lambda_function.migrator.function_name}" ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "title": "Invocations",
                "stat": "Sum",
                "period": 60,
                "yAxis": {
                    "left": {
                        "showUnits": false,
                        "min": 0
                    },
                    "right": {
                        "showUnits": false,
                        "min": 0
                    }
                },
                "legend": {
                    "position": "hidden"
                }
            }
        },
        {
            "height": 6,
            "width": 24,
            "y": 121,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/Lambda", "Duration", "FunctionName", "${aws_lambda_function.migrator.function_name}" ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "title": "Duration",
                "stat": "Sum",
                "period": 60,
                "yAxis": {
                    "left": {
                        "showUnits": false,
                        "min": 0
                    },
                    "right": {
                        "showUnits": false,
                        "min": 0
                    }
                },
                "legend": {
                    "position": "hidden"
                }
            }
        }, 
        {
            "height": 1,
            "width": 24,
            "y": 127,
            "x": 0,
            "type": "text",
            "properties": {
                "markdown": "# API tests "
            }
        },
        {
            "height": 6,
            "width": 24,
            "y": 128,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '${aws_cloudwatch_log_group.api_tests[0].name}' | fields @message\n| sort @timestamp desc",
                "region": "${var.region}",
                "stacked": false,
                "title": "Top log templates",
                "view": "table"
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 134,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/Lambda", "Errors", "FunctionName", "${aws_lambda_function.api_tests[0].function_name}" ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "title": "Errors",
                "stat": "Sum",
                "period": 60,
                "yAxis": {
                    "left": {
                        "showUnits": false,
                        "min": 0
                    },
                    "right": {
                        "showUnits": false,
                        "min": 0
                    }
                },
                "legend": {
                    "position": "hidden"
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 134,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/Lambda", "Invocations", "FunctionName", "${aws_lambda_function.api_tests[0].function_name}" ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "title": "Invocations",
                "stat": "Sum",
                "period": 60,
                "yAxis": {
                    "left": {
                        "showUnits": false,
                        "min": 0
                    },
                    "right": {
                        "showUnits": false,
                        "min": 0
                    }
                },
                "legend": {
                    "position": "hidden"
                }
            }
        },
        {
            "height": 6,
            "width": 24,
            "y": 140,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/Lambda", "Duration", "FunctionName", "${aws_lambda_function.api_tests[0].function_name}" ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "title": "Duration",
                "stat": "Sum",
                "period": 60,
                "yAxis": {
                    "left": {
                        "showUnits": false,
                        "min": 0
                    },
                    "right": {
                        "showUnits": false,
                        "min": 0
                    }
                },
                "legend": {
                    "position": "hidden"
                }
            }
        },
        {
            "type": "text",
            "x": 0,
            "y": 146,
            "width": 24,
            "height": 1,
            "properties": {
                "markdown": "# Load Tests"
            }
        },
        {
            "height": 6,
            "width": 24,
            "y": 147,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '/aws/lambda/${aws_lambda_function.load_tests.function_name}' | fields @message\n| sort @timestamp desc",
                "region": "${var.region}",
                "stacked": false,
                "title": "Top log templates",
                "view": "table"
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 153,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/Lambda", "Errors", "FunctionName", "${aws_lambda_function.load_tests.function_name}" ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "title": "Errors",
                "stat": "Sum",
                "period": 60,
                "yAxis": {
                    "left": {
                        "showUnits": false,
                        "min": 0
                    },
                    "right": {
                        "showUnits": false,
                        "min": 0
                    }
                },
                "legend": {
                    "position": "hidden"
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 153,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/Lambda", "Invocations", "FunctionName", "${aws_lambda_function.load_tests.function_name}" ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "title": "Invocations",
                "stat": "Sum",
                "period": 60,
                "yAxis": {
                    "left": {
                        "showUnits": false,
                        "min": 0
                    },
                    "right": {
                        "showUnits": false,
                        "min": 0
                    }
                },
                "legend": {
                    "position": "hidden"
                }
            }
        },
        {
            "height": 6,
            "width": 24,
            "y": 159,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/Lambda", "Duration", "FunctionName", "${aws_lambda_function.load_tests.function_name}" ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "title": "Duration",
                "stat": "Sum",
                "period": 60,
                "yAxis": {
                    "left": {
                        "showUnits": false,
                        "min": 0
                    },
                    "right": {
                        "showUnits": false,
                        "min": 0
                    }
                },
                "legend": {
                    "position": "hidden"
                }
            }
        }
    ]
}
EOF
  
  default_tags = {
    Service = var.application_name
    Application = "Tracker"
    Team = "Tracker"
    ManagedBy = "Terraform"
    Environment = var.environment
  }
}
