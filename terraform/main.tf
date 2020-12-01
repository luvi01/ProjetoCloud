terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "default"
  
}

provider "aws" {
  alias = "east2"
  region  = "us-east-2"
  profile = "default"
  
}

module "ssh_key_pair" {
  providers = {
    aws = aws.east2
  }
  source                = "git::https://github.com/cloudposse/terraform-aws-key-pair.git?ref=master"
  namespace             = "eg"
  stage                 = "prod"
  name                  = "app"
  ssh_public_key_path   = "./"
  generate_ssh_key      = "true"
  private_key_extension = ".pem"
  public_key_extension  = ".pub"
}

module "database"{
  source = "./modules/database"
}

module "orm"{
  source = "./modules/orm"
  keyName = module.ssh_key_pair.key_name
  dbName = module.database.this_db_instance_name
  dbUser = module.database.this_db_instance_username
  dbPass = module.database.this_db_instance_password
  dbHost = module.database.this_db_instance_endpoint
  dbPort = module.database.this_db_instance_port
  providers = {
    aws = aws.east2
  }
}