data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}



module "orm_sg" {
  source = "terraform-aws-modules/security-group/aws"


  name        = "Security ORM"
  description = "Security group for database"
  //vpc_id      = "vpc-bcbf0fc6"
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

module "orm_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  version = "2.12.0"
  name           = "ORM"
  instance_count = 1
  key_name       = "luvi2"
  ami                    = "ami-0a91cd140a1fc148a"
  instance_type          = "t2.micro"
  subnet_ids              = data.aws_subnet_ids.all.ids
  vpc_security_group_ids      = [module.orm_sg.this_security_group_id]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }

  user_data = templatefile("${path.module}/install.sh", {dbName = var.dbName,
                                                         dbUser = var.dbUser,
                                                         dbPass = var.dbPass,
                                                         dbHost = substr(var.dbHost, 0, -5),
                                                         dbPort = var.dbPort})

}