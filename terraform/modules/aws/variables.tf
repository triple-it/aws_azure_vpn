locals {
  availability_zones = [
    data.aws_availability_zones.main.names[0],
    data.aws_availability_zones.main.names[1],
    data.aws_availability_zones.main.names[2],
  ]

  public_subnets = [
    cidrsubnet(var.vpc_cidr, 6, 0),
    cidrsubnet(var.vpc_cidr, 6, 1),
    cidrsubnet(var.vpc_cidr, 6, 2),
  ]

  private_subnets = [
    cidrsubnet(var.vpc_cidr, 6, 4),
    cidrsubnet(var.vpc_cidr, 6, 5),
    cidrsubnet(var.vpc_cidr, 6, 6),
  ]

  database_subnets = [
    cidrsubnet(var.vpc_cidr, 6, 7),
    cidrsubnet(var.vpc_cidr, 6, 8),
    cidrsubnet(var.vpc_cidr, 6, 9),
  ]

  tags = var.tags

  vpc_route_tables = flatten([module.vpc.private_route_table_ids, module.vpc.public_route_table_ids])
}

variable "azure_vnet_cidr" {
  description = "Azure VNET CIDR block"
  type        = string
}

variable "azure_gateway_ip" {
  description = "Azure Gateway IP"
  type        = string
}

variable "environment" {
  description = "Environment to be built"
  type        = string
}

variable "instance_type" {
  description = "Instance type for MSSQL instance"
  type        = string
}

variable "tags" {
  description = "Tags to be applied to resources"
  type        = map(string)
}

variable "vpc_cidr" {
  description = "CIDR of VPC"
  type        = string
}