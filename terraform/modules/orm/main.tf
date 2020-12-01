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

module "orm_elb" {
  source = "terraform-aws-modules/elb/aws"

  depends_on = [module.orm_sg]
  name = "orm-elb"

  subnets         = data.aws_subnet_ids.all.ids
  security_groups = [module.orm_sg.this_security_group_id]
  internal        = false


  listener = [
    {
      instance_port     = "8080"
      instance_protocol = "tcp"
      lb_port           = "8080"
      lb_protocol       = "tcp"
    },
  ]


  health_check = {
    target              = "TCP:8080"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 20
  }

}

module "backend_asg" {
  source = "terraform-aws-modules/autoscaling/aws"

  name = "ORM-asg"
 
  launch_configuration = aws_launch_configuration.orm_config.name
  create_lc = false 
  recreate_asg_when_lc_changes = true

  security_groups = [module.orm_sg.this_security_group_id]
  load_balancers  = [module.orm_elb.this_elb_id]

  asg_name                  = "orm-asg"
  vpc_zone_identifier       = data.aws_subnet_ids.all.ids
  health_check_type         = "EC2"
  min_size                  = 2
  max_size                  = 5
  desired_capacity          = 2
  wait_for_capacity_timeout = 0

}

resource "null_resource" "client" {
  provisioner "local-exec" {
    command = <<EOT
    cd ..
    cd client
    sed -i '' "s/.*#url.*/url = '${module.orm_elb.this_elb_dns_name}:8080' #url/g" client.py
    EOT
  }

}

  
