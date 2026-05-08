locals {
  name_prefix = "${var.project}-${var.env}"
}

# ----------------------------------------------------------------
# ECR
# ----------------------------------------------------------------
resource "aws_ecr_repository" "app" {
  name                 = "${local.name_prefix}-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${local.name_prefix}-app"
  }
}

# ----------------------------------------------------------------
# CloudWatch Logs
# ----------------------------------------------------------------
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${local.name_prefix}"
  retention_in_days = 30

  tags = {
    Name = "${local.name_prefix}-ecs-logs"
  }
}

# ----------------------------------------------------------------
# Secrets Manager（器のみ作成。値は手動 or CI で投入）
# ----------------------------------------------------------------
resource "aws_secretsmanager_secret" "database_url" {
  name = "${local.name_prefix}/DATABASE_URL"

  tags = {
    Name = "${local.name_prefix}-database-url"
  }
}

resource "aws_secretsmanager_secret" "secret_key_base" {
  name = "${local.name_prefix}/SECRET_KEY_BASE"

  tags = {
    Name = "${local.name_prefix}-secret-key-base"
  }
}

# ----------------------------------------------------------------
# IAM
# ----------------------------------------------------------------
data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_execution" {
  name               = "${local.name_prefix}-ecs-task-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

resource "aws_iam_role_policy_attachment" "task_execution_managed" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "secrets_read" {
  statement {
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      aws_secretsmanager_secret.database_url.arn,
      aws_secretsmanager_secret.secret_key_base.arn,
    ]
  }
}

resource "aws_iam_policy" "secrets_read" {
  name   = "${local.name_prefix}-secrets-read"
  policy = data.aws_iam_policy_document.secrets_read.json
}

resource "aws_iam_role_policy_attachment" "task_execution_secrets" {
  role       = aws_iam_role.task_execution.name
  policy_arn = aws_iam_policy.secrets_read.arn
}

resource "aws_iam_role" "task_role" {
  name               = "${local.name_prefix}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

# ----------------------------------------------------------------
# ECS Cluster
# ----------------------------------------------------------------
resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-cluster"

  tags = {
    Name = "${local.name_prefix}-cluster"
  }
}

# ----------------------------------------------------------------
# ECS Task Definition
# ----------------------------------------------------------------
resource "aws_ecs_task_definition" "app" {
  family                   = "${local.name_prefix}-app"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = var.rails_image
      essential = true

      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "CORS_ALLOWED_ORIGINS"
          value = var.cors_allowed_origins
        },
        {
          name  = "RAILS_LOG_TO_STDOUT"
          value = "true"
        }
      ]

      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = aws_secretsmanager_secret.database_url.arn
        },
        {
          name      = "SECRET_KEY_BASE"
          valueFrom = aws_secretsmanager_secret.secret_key_base.arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "app"
        }
      }
    }
  ])

  tags = {
    Name = "${local.name_prefix}-app-task"
  }
}

# ----------------------------------------------------------------
# ALB
# ----------------------------------------------------------------
resource "aws_lb" "main" {
  # AWS ALB 名の上限は 32 文字。project 変数が長い場合は短縮すること
  name               = substr("${local.name_prefix}-alb", 0, 32)
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.sg_alb_id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = "${local.name_prefix}-alb"
  }
}

resource "aws_lb_target_group" "app" {
  # AWS ターゲットグループ名の上限は 32 文字
  name        = substr("${local.name_prefix}-app-tg", 0, 32)
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/healthz"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${local.name_prefix}-app-tg"
  }
}

# デフォルト: X-Origin-Verify ヘッダーがない場合 403 を返す
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "403"
    }
  }
}

# X-Origin-Verify ヘッダーが一致する場合のみ ECS へ転送
resource "aws_lb_listener_rule" "verify_header" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  condition {
    http_header {
      http_header_name = "X-Origin-Verify"
      values           = [var.origin_verify_secret]
    }
  }
}

# ----------------------------------------------------------------
# ECS Service
# ----------------------------------------------------------------
resource "aws_ecs_service" "app" {
  name            = "${local.name_prefix}-app-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  # NAT Gateway 省略のため ECS を public subnet に配置してパブリック IP を付与
  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = [var.sg_ecs_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener_rule.verify_header]

  tags = {
    Name = "${local.name_prefix}-app-service"
  }
}
