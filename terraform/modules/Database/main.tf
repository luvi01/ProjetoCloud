data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

module "db_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "Security DB"
  description = "Security group for database"
  vpc_id      = data.aws_vpc.default.id


  ingress_cidr_blocks      = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp"]
  egress_rules        = ["all-all"]

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      rule        = "postgresql-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}

module "db_rds" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "demodb-postgres"

  engine            = "postgres"
  engine_version    = "9.6.9"
  instance_class    = "db.t2.large"
  allocated_storage = 5
  storage_encrypted = false

  name = "demodb"

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  username = "demouser"

  password = "YourPwdShouldBeLongAndSecure!"
  port     = "5432"

  vpc_security_group_ids = [module.db_sg.this_security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # disable backups to create DB faster
  backup_retention_period = 0

  tags = {
    Owner       = "user"
    Environment = "dev"
  }

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # DB subnet group
  subnet_ids = data.aws_subnet_ids.all.ids

  # DB parameter group
  family = "postgres9.6"

  # DB option group
  major_engine_version = "9.6"

  # Snapshot name upon DB deletion
  final_snapshot_identifier = "demodb"

  # Database Deletion Protection
  deletion_protection = false

  publicly_accessible = true
}

output "this_db_instance_name" {
  value = module.db_rds.this_db_instance_name
}

output "this_db_instance_username" {
  value = module.db_rds.this_db_instance_username
}

output "this_db_instance_password" {
  value = module.db_rds.this_db_instance_password
}

output "this_db_instance_endpoint" {
  value = module.db_rds.this_db_instance_address
}

output "this_db_instance_port" {
  value = module.db_rds.this_db_instance_port
}