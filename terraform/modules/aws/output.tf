output "ec2_private_ip" {
  value = aws_instance.windows.private_ip
}