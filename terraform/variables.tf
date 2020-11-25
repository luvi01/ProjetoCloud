# Input variable definitions

variable "vpc_tags" {
  description = "Tags to apply to resources created by VPC module"
  type        = map(string)
  default     = {
    Terraform   = "true"
    Environment = "dev"
  }
}
