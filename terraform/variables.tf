locals {
  environment = replace(var.environment, "_", "-")
}

variable "aws_region" {
  description = "AWS Region to deploy resources"
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment name we are building"
  default     = "aws_azure_vpn"
}

variable "my_name" {
  description = "My name"
  default     = "Roderick Groesbeek"
}

variable "tags" {
  description = "Default tags for this environment"
  default     = {}
}
