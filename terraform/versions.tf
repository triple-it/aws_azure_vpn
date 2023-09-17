provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Owner       = var.my_name
      Project     = var.environment
      Provisioner = "Terraform"
    }
  }
}

provider "azurerm" {
  features {}
}

terraform {
  required_version = "~> 1.5.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}
