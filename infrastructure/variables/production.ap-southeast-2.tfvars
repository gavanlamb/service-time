environment="Production"

region="ap-southeast-2"

application_name="Time"

vpc_name="expensely"
db_subnet_group_name="expensely"

cluster_name="expensely"
capacity_provider_name="linux"

codedeploy_role_name="expensely-code-deploy"
codedeploy_bucket_name="expensely-code-deploy-production"
codedeploy_bucket_policy_name="expensely-code-deploy"

zone_name="expensely.io"
subdomain="time"
alb_name="expensely"

api_ecs_task_cpu=512
api_ecs_task_memory=2042
api_min_capacity=1
api_max_capacity=2
api_desired_count=1

cognito_name="expensely"

rds_delete_protection=true
rds_database_name="time_api"

placement_strategies=[
  {
    type = "spread"
    field = "attribute:ecs.availability-zone"
  },
  {
    field = "cpu",
    type = "binpack"
  }
]
