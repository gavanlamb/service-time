region="ap-southeast-2"

application_name="Time"

vpc_name="expensely"
db_subnet_group_name="expensely"

cluster_name="expensely"
capacity_provider_name="linux"

codedeploy_role_name="expensely-code-deploy"
codedeploy_bucket_name="expensely-code-deploy-production"

zone_name="preview.expensely.io"
alb_name="expensely"

api_ecs_task_cpu=512
api_ecs_task_memory=2042
api_min_capacity=2
api_max_capacity=10
api_desired_count=2

cognito_name="expensely-preview"

test_results_bucket="expensely-test-results-production"
test_results_bucket_policy_name="expensely-test-results"

rds_delete_protection=false
rds_database_name="time"
