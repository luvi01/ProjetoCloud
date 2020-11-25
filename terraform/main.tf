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

module "Database"{
  source = "./modules/Database"
}

module "Orm"{
  source = "./modules/Orm"
  dbName = module.Database.this_db_instance_name
  dbUser = module.Database.this_db_instance_username
  dbPass = module.Database.this_db_instance_password
  dbHost = module.Database.this_db_instance_endpoint
  dbPort = module.Database.this_db_instance_port
  providers = {
    aws = aws.east2
  }
}