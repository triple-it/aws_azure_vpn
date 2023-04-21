locals {
  aws_vpc_cidr = "10.190.0.0/16"

  azure_gateway_ip = "20.127.105.184"

  azure_vnet_cidr = "10.191.0.0/16"
}

module "aws" {
  source = "./modules/aws"

  azure_gateway_ip = local.azure_gateway_ip
  azure_vnet_cidr  = local.azure_vnet_cidr
  environment      = var.environment
  instance_type    = "m5.large"
  tags             = var.tags
  vpc_cidr         = local.aws_vpc_cidr
}
