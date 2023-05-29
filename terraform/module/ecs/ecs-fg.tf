########## Create dependancy service for ECS Cluster service

## Get Public Security Group to apply for the Database
data "aws_security_group" "public_sg" {
  tags = {
    Name = "PUBLIC_SG"
  }
}

## Get Private Security Group to apply for the Database
data "aws_security_group" "private_sg" {
  tags = {
    Name = "PRIVATE_SG"
  }
}

## Get Public SubnetList
data "aws_subnets" "public_subnets" {
    filter {
      name = "tag:Access"
      values = ["PUBLIC"]
    }
}

## Get Private SubnetList
data "aws_subnets" "private_subnets" {
    filter {
      name = "tag:Access"
      values = ["PRIVATE"]
    }
}

############## Use available roles to link to user or service

## Create ecsServiceRole role with Policy "AmazonEC2ContainerServiceRole"
/*
data "aws_iam_role" "role_ecsServiceRole" {
  name = "ecsServiceRole"
}
data "aws_iam_policy" "AmazonEC2ContainerServiceRolePolicy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"  
}
*/
resource "aws_iam_role" "ecsServiceRoleNew" {
  name = "ecsServiceRoleNew"

  assume_role_policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "ecs.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}
/*
resource "aws_iam_role_policy_attachment" "EcsEc2PolicyRoleAttach" {
  role       = aws_iam_role.ecsServiceRoleNew.name
  policy_arn = "arn:aws:iam::aws:policy/aws-service-role/AmazonECSServiceRolePolicy"
}
*/


## Creating policy for ecsServiceRoleNew
resource "aws_iam_role_policy" "ecsServiceRoleNew_policy" {
  name = aws_iam_role.ecsServiceRoleNew.name
  role = aws_iam_role.ecsServiceRoleNew.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ECSTaskManagement",
            "Effect": "Allow",
            "Action": [
                "ec2:AttachNetworkInterface",
                "ec2:CreateNetworkInterface",
                "ec2:CreateNetworkInterfacePermission",
                "ec2:DeleteNetworkInterface",
                "ec2:DeleteNetworkInterfacePermission",
                "ec2:Describe*",
                "ec2:DetachNetworkInterface",
                "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
                "elasticloadbalancing:DeregisterTargets",
                "elasticloadbalancing:Describe*",
                "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
                "elasticloadbalancing:RegisterTargets",
                "route53:ChangeResourceRecordSets",
                "route53:CreateHealthCheck",
                "route53:DeleteHealthCheck",
                "route53:Get*",
                "route53:List*",
                "route53:UpdateHealthCheck",
                "servicediscovery:DeregisterInstance",
                "servicediscovery:Get*",
                "servicediscovery:List*",
                "servicediscovery:RegisterInstance",
                "servicediscovery:UpdateInstanceCustomHealthStatus"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AutoScaling",
            "Effect": "Allow",
            "Action": [
                "autoscaling:Describe*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AutoScalingManagement",
            "Effect": "Allow",
            "Action": [
                "autoscaling:DeletePolicy",
                "autoscaling:PutScalingPolicy",
                "autoscaling:SetInstanceProtection",
                "autoscaling:UpdateAutoScalingGroup"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "autoscaling:ResourceTag/AmazonECSManaged": "false"
                }
            }
        },
        {
            "Sid": "AutoScalingPlanManagement",
            "Effect": "Allow",
            "Action": [
                "autoscaling-plans:CreateScalingPlan",
                "autoscaling-plans:DeleteScalingPlan",
                "autoscaling-plans:DescribeScalingPlans"
            ],
            "Resource": "*"
        },
        {
            "Sid": "CWAlarmManagement",
            "Effect": "Allow",
            "Action": [
                "cloudwatch:DeleteAlarms",
                "cloudwatch:DescribeAlarms",
                "cloudwatch:PutMetricAlarm"
            ],
            "Resource": "arn:aws:cloudwatch:*:*:alarm:*"
        },
        {
            "Sid": "ECSTagging",
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags"
            ],
            "Resource": "arn:aws:ec2:*:*:network-interface/*"
        },
        {
            "Sid": "CWLogGroupManagement",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:DescribeLogGroups",
                "logs:PutRetentionPolicy"
            ],
            "Resource": "arn:aws:logs:*:*:log-group:/aws/ecs/*"
        },
        {
            "Sid": "CWLogStreamManagement",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:log-group:/aws/ecs/*:log-stream:*"
        },
        {
            "Sid": "ExecuteCommandSessionManagement",
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeSessions"
            ],
            "Resource": "*"
        },
        {
            "Sid": "ExecuteCommand",
            "Effect": "Allow",
            "Action": [
                "ssm:StartSession"
            ],
            "Resource": [
                "arn:aws:ecs:*:*:task/*",
                "arn:aws:ssm:*:*:document/AmazonECS-ExecuteInteractiveCommand"
            ]
        },
        {
            "Sid": "CloudMapResourceCreation",
            "Effect": "Allow",
            "Action": [
                "servicediscovery:CreateHttpNamespace",
                "servicediscovery:CreateService"
            ],
            "Resource": "*",
            "Condition": {
                "ForAllValues:StringEquals": {
                    "aws:TagKeys": [
                        "AmazonECSManaged"
                    ]
                }
            }
        },
        {
            "Sid": "CloudMapResourceTagging",
            "Effect": "Allow",
            "Action": "servicediscovery:TagResource",
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "aws:RequestTag/AmazonECSManaged": "*"
                }
            }
        },
        {
            "Sid": "CloudMapResourceDeletion",
            "Effect": "Allow",
            "Action": [
                "servicediscovery:DeleteService"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:ResourceTag/AmazonECSManaged": "false"
                }
            }
        },
        {
            "Sid": "CloudMapResourceDiscovery",
            "Effect": "Allow",
            "Action": [
                "servicediscovery:DiscoverInstances"
            ],
            "Resource": "*"
        }
    ]
})
}



## Create ecsTaskExecutionRole role with Policy "AmazonECSTaskExecutionRolePolicy"
/*
data "aws_iam_role" "role_ecsTaskExecutionRole" {
  name = "ecsTaskExecutionRole"
}
*/
resource "aws_iam_role" "ecsTaskExecutionRoleNew" {
  name = "ecsTaskExecutionRoleNew"

  assume_role_policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "ecs-tasks.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "EcsTaskExcPolicyRoleAttach_policy" {
  name = aws_iam_role.ecsTaskExecutionRoleNew.name
  role = aws_iam_role.ecsTaskExecutionRoleNew.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
})
}

## Create ecsAutoscaleRole role with Policy "AmazonEC2ContainerServiceAutoscaleRole"
/*
data "aws_iam_role" "role_ecsAutoscaleRole" {
  name = "ecsAutoscaleRole"
}

resource "aws_iam_role" "ecsAutoscaleRole" {
  name = "ecsAutoscaleRoleNew"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "application-autoscaling.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "EcsServiceAutoScalePolicyRoleAttach" {
  role       = aws_iam_role.ecsAutoscaleRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}
*/

## Create ecsInstanceRole role with Policy "AmazonEC2ContainerServiceforEC2Role"
/*
data "aws_iam_role" "role_ecsInstanceRole" {
  name = "ecsInstanceRole"
}

resource "aws_iam_role" "ecsInstanceRoleNew" {
  name = "ecsInstanceRoleNew"

  assume_role_policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "Ec2ContainerServicePolicyRoleAttach" {
  role       = aws_iam_role.ecsInstanceRoleNew.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
*/

##----------------------------------##

/*
## Create random value to set for IAM instance profile
resource "random_string" "instance_profile"{
  length           = 8
  special          = false
  override_special = "-"
}
# Create Instance Profile for ECS EC2 instances to use in Launch Configuration
resource "aws_iam_instance_profile" "ecs_agent_profile" {
  name = "ecsagent-${random_string.instance_profile.result}"
  role = aws_iam_role.ecsInstanceRoleNew.name
}
*/


## Create S3 bucket for access_logs
resource "aws_s3_bucket" "lb_logs" {
  bucket = var.alb_access_log_s3_bucket
  force_destroy = true ## To handle none empty S3 bucket. Destroy with Terraform destroy.
  
  tags = {
    Name        = "ALB_LOG_Bucket"
  }
}

## GEt the service Account ID
data "aws_elb_service_account" "service_account_id" {}
## Get the callert identity
data "aws_caller_identity" "caller_identity" {}
## Apply bucket policy to the bucket
resource "aws_s3_bucket_policy" "access_logs_policy" {
    bucket = aws_s3_bucket.lb_logs.id
    policy = jsonencode({
    Version: "2012-10-17",
    Id: "AWSConsole-AccessLogs-Policy-1668059634986",
    Statement: [
        {
            Sid: "AWSConsoleStmt-1668059634986",
            Effect: "Allow",
            Principal: {
                AWS: "${data.aws_elb_service_account.service_account_id.arn}"
            },
            Action: "s3:PutObject",
            Resource: "${aws_s3_bucket.lb_logs.arn}/AWSLogs/${data.aws_caller_identity.caller_identity.account_id}/*"
        },
        {
            Sid: "AWSLogDeliveryWrite",
            Effect: "Allow",
            Principal: {
                Service: "delivery.logs.amazonaws.com"
            },
            Action: "s3:PutObject",
            Resource: "${aws_s3_bucket.lb_logs.arn}/AWSLogs/${data.aws_caller_identity.caller_identity.account_id}/*",
            Condition: {
                StringEquals: {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        },
        {
            Sid: "AWSLogDeliveryAclCheck",
            Effect: "Allow",
            Principal: {
                "Service": "delivery.logs.amazonaws.com"
            },
            Action: "s3:GetBucketAcl",
            Resource: "${aws_s3_bucket.lb_logs.arn}"
        }
    ]
    })
}

## Enable SSE encryption for the bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs_encryption" {
  bucket = "${aws_s3_bucket.lb_logs.bucket}"

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}
###############################################

# Create Application Load balancer
resource "aws_lb" "ecs_lb" {
  name               = "opstools-ppe"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.public_sg.id]
  subnets            = data.aws_subnets.public_subnets.ids
  ip_address_type = "ipv4"

  enable_deletion_protection = false
  tags = {
    Environment = "Project"
  }
  access_logs {
    bucket  = aws_s3_bucket.lb_logs.bucket
    enabled = true
  }
  depends_on = [
    aws_s3_bucket.lb_logs,
    aws_s3_bucket_policy.access_logs_policy
  ]
  drop_invalid_header_fields = true
}



# Target Group for ALB Primary
resource "aws_lb_target_group" "ecs_alb_tg1" {
  name     = "ecs-alb-tg1"
  target_type = "ip"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    healthy_threshold   = "5"
    interval            = "30"
    unhealthy_threshold = "2"
    timeout             = "20"
    path                = "/"
  }
}

# Target Group for ALB Secondary
resource "aws_lb_target_group" "ecs_alb_tg2" {
  name     = "ecs-alb-tg2"
  target_type = "ip"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    healthy_threshold   = "5"
    interval            = "30"
    unhealthy_threshold = "2"
    timeout             = "20"
    path                = "/"
  }
}


# Links ALB to TG with lister rule primary
resource "aws_lb_listener" "alb_to_tg1" {
  load_balancer_arn = aws_lb.ecs_lb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.ecs_alb_tg1.id
    type = "forward"
    /*
    redirect {
      port = 443
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
    */
  }
}

# Links ALB to TG with lister rule secondary
resource "aws_lb_listener" "alb_to_tg2" {
  load_balancer_arn = aws_lb.ecs_lb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.ecs_alb_tg2.id
    type = "forward"
    /*
    redirect {
      port = 443
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
    */
  }
}


# Create ECR repository for the image to store
resource "aws_ecr_repository" "project_repo" {
  name = "project_repo_aws"
  image_tag_mutability = "MUTABLE"
  force_delete = true # This will remove the repo with all the images as well in it.

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Create ECS Cluster
resource "aws_ecs_cluster" "project_cluster" {
  name = "project_cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

/*
# Task definitions to use in Service
resource "aws_ecs_task_definition" "project_task" {
  family = "project_task"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  execution_role_arn = aws_iam_role.ecsTaskExecutionRoleNew.arn
  container_definitions = jsonencode([
    {
      name = "AppTask"
      image = aws_ecr_repository.project_repo.repository_url
      cpu = 10
      memory = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
  depends_on = [
    aws_ecr_repository.project_repo
  ]
}
*/
# aws_ecr_repository.project_repo.repository_url

# Create a ecs task definitions
resource "aws_ecs_task_definition" "project_task" {
  family                   = "project_task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn = aws_iam_role.ecsTaskExecutionRoleNew.arn
  cpu                      = 1024
  memory                   = 2048
  container_definitions    = jsonencode([
    {
      name = "AppTask"
      image = aws_ecr_repository.project_repo.repository_url
      cpu = 10
      memory = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

/*
# ECS Service configuration - This block maintain the link between all services.
resource "aws_ecs_service" "service_node_app" {
  name            = "service_node_app"
  cluster         = aws_ecs_cluster.project_cluster.id
  task_definition = aws_ecs_task_definition.project_task.arn
  enable_ecs_managed_tags = true
  desired_count   = 1
  launch_type = "FARGATE"
  health_check_grace_period_seconds = 60
  wait_for_steady_state = false
  #iam_role        = aws_iam_role.ecsServiceRoleNew.arn
  network_configuration {
    subnets = data.aws_subnets.private_subnets.ids
    assign_public_ip = false
    security_groups = [data.aws_security_group.private_sg.id]
  }
  depends_on      = [
    aws_ecs_cluster.project_cluster, 
    aws_ecs_task_definition.project_task,
    aws_lb_listener.alb_to_tg1,
    aws_lb_listener.alb_to_tg2,
    aws_lb_target_group.ecs_alb_tg1,
    aws_lb_target_group.ecs_alb_tg2
    ]
  lifecycle {
    ignore_changes = [desired_count]
  }
  
  ## Remove the loadbalancer from ECS service and assign from CodeDeploy
  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_alb_tg1.arn
    container_name   = "AppTask"
    container_port   = 80
  }
  /*
  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_alb_tg2.arn
    container_name   = "AppTask"
    container_port   = 80
  }
  
  deployment_controller {
    type = "CODE_DEPLOY"
  }
  */
  /*
}
*/

# ECS Service configuration for Blue-Green deployment
resource "aws_ecs_service" "service_node_app" {
  name            = "service_node_app"
  cluster         = aws_ecs_cluster.project_cluster.id
  task_definition = aws_ecs_task_definition.project_task.arn
  enable_ecs_managed_tags = true
  desired_count   = 1
  launch_type = "FARGATE"
  health_check_grace_period_seconds = 60
  wait_for_steady_state = false
  scheduling_strategy = "REPLICA"
  platform_version = "LATEST"
  #iam_role        = aws_iam_role.ecsServiceRoleNew.arn
  network_configuration {
    subnets = data.aws_subnets.private_subnets.ids
    assign_public_ip = false
    security_groups = [data.aws_security_group.private_sg.id]
  }
  depends_on      = [
    aws_ecs_cluster.project_cluster, 
    aws_ecs_task_definition.project_task,
    aws_lb_listener.alb_to_tg1,
    aws_lb_listener.alb_to_tg2,
    aws_lb_target_group.ecs_alb_tg1,
    aws_lb_target_group.ecs_alb_tg2
    ]
  lifecycle {
    ignore_changes = [desired_count]
  }
  
  ## Remove the loadbalancer from ECS service and assign from CodeDeploy
  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_alb_tg1.arn
    container_name   = "AppTask"
    container_port   = 80
  }
  /*
  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_alb_tg2.arn
    container_name   = "AppTask"
    container_port   = 80
  }
  */
  deployment_controller {
    type = "CODE_DEPLOY"
  }
  
}


# Autoscaling for ECS Service instances
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.max_tasks
  min_capacity       = var.min_tasks
  resource_id        = "service/${aws_ecs_cluster.project_cluster.name}/${aws_ecs_service.service_node_app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Autoscaling policy - If the CPU level above 70% it will scale up.
resource "aws_appautoscaling_policy" "ecs_policy" {
  name               = "scale_in_out"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = var.ecs_task_avg_cpu_target
    scale_out_cooldown = 120
    scale_in_cooldown = 120
  }
}