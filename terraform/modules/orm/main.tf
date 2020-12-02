data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

module "orm_sg" {
  source = "terraform-aws-modules/security-group/aws"


  name        = "Security ORM"
  description = "Security group for ORM"
  vpc_id      = data.aws_vpc.default.id

  ingress_with_cidr_blocks = [
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "Tasks"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow all outgoing traffic"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

resource "aws_launch_configuration" "orm_config" {
  name_prefix   = "orm-config"
  image_id      = "ami-0a91cd140a1fc148a"
  instance_type = "t2.micro"
  user_data = templatefile("${path.module}/install.sh", {dbName = var.dbName,
                                                         dbUser = var.dbUser,
                                                         dbPass = var.dbPass,
                                                         dbHost = var.dbHost,
                                                         dbPort = var.dbPort})
  
  security_groups  = [module.orm_sg.this_security_group_id]
  key_name = var.keyName

  lifecycle {
    create_before_destroy = true
  }
}

module "orm_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"
  
  name = "orm-alb"

  load_balancer_type = "application"

  vpc_id          = data.aws_vpc.default.id
  subnets         = data.aws_subnet_ids.all.ids
  security_groups = [module.orm_sg.this_security_group_id]

  target_groups = [
    {
      name_prefix      = "task-"
      backend_protocol = "HTTP"
      backend_port     = 8080
      target_type      = "instance"
      health_check = {
        path           = "/status"
        port           = 8080
        protocol       = "HTTP"
        matcher        = "200"
      }

    }
  ]

  http_tcp_listeners = [
    {
      port               = 8080
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

}

module "orm_asg" {
  source = "terraform-aws-modules/autoscaling/aws"

  name = "ORM-asg"
 
  launch_configuration = aws_launch_configuration.orm_config.name
  create_lc = false 
  recreate_asg_when_lc_changes = true

  security_groups = [module.orm_sg.this_security_group_id]
  target_group_arns = module.orm_alb.target_group_arns

  asg_name                  = "orm-asg"
  vpc_zone_identifier       = data.aws_subnet_ids.all.ids
  health_check_type         = "EC2"
  min_size                  = 1
  max_size                  = 5
  desired_capacity          = 2
  wait_for_capacity_timeout = 0

}

resource "aws_autoscaling_policy" "orm_asg_policy" {
  depends_on = [module.orm_asg]
  name                   = "orm-asg-policy"
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label = "${module.orm_alb.this_lb_arn_suffix}/${module.orm_alb.target_group_arn_suffixes[0]}"
    }

    target_value = 3000
  }

  autoscaling_group_name = module.orm_asg.this_autoscaling_group_name
}

resource "null_resource" "client" {
  provisioner "local-exec" {
    command = <<EOT
    cd ..
    cd client
    sed -i '' "s/.*#url.*/url = '${module.orm_alb.this_lb_dns_name}:8080' #url/g" client.py
    EOT
  }

}

  
