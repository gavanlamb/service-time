region="ap-southeast-2"

application_name="Time"

vpc_name="expensely"

cluster_name="expensely"
capacity_provider_name="linux"

cognito_user_pool_name="expensely"

codedeploy_role_name="expensely-code-deploy"

zone_name="preview.expensely.io"
alb_name="expensely"

api_ecs_task_cpu=512
api_ecs_task_memory=2042
api_min_capacity=2
api_max_capacity=10
api_desired_count=2
