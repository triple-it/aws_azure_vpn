module "key" {
  source = "../ssh_keypair"

  name = var.environment
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.environment}_ec2_role"
  role = aws_iam_role.ec2_role.name

  tags = var.tags
}

resource "aws_iam_role" "ec2_role" {
  name = "${var.environment}_ec2_role"

  assume_role_policy = data.aws_iam_policy_document.ec2_role.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = data.aws_iam_policy.AmazonSSMManagedInstanceCore.arn
}

resource "aws_instance" "windows" {
  ami                     = data.aws_ami.windows_2019.id
  disable_api_termination = false
  ebs_optimized           = true
  iam_instance_profile    = aws_iam_instance_profile.this.name
  instance_type           = var.instance_type
  key_name                = module.key.key_name
  monitoring              = true
  vpc_security_group_ids  = [aws_security_group.this.id]
  subnet_id               = module.vpc.private_subnets[0]

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 3
    http_tokens                 = "required"
  }

  tags        = merge(var.tags, { "Name" = "${var.environment}_mssql" })
  volume_tags = merge(var.tags, { "Name" = "${var.environment}_mssql" })

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
  }

  lifecycle {
    ignore_changes = [user_data, ami]
  }
}

resource "aws_security_group" "this" {
  description = "Security group for Azure-AWS tunnel communication"
  name        = var.environment
  vpc_id      = module.vpc.vpc_id

  tags = merge(var.tags, {
    Name = var.environment
  })
}

resource "aws_security_group_rule" "egress" {
  from_port         = 0
  protocol          = -1
  security_group_id = aws_security_group.this.id
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ingress_azure" {
  from_port         = 0
  protocol          = -1
  security_group_id = aws_security_group.this.id
  to_port           = 0
  type              = "ingress"
  cidr_blocks       = [var.azure_vnet_cidr]
}

resource "aws_security_group_rule" "self" {
  from_port         = 0
  protocol          = -1
  security_group_id = aws_security_group.this.id
  to_port           = 0
  type              = "ingress"
  self              = true
}
