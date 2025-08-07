provider "aws" {
  region = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content  = tls_private_key.ec2_key.private_key_pem
  filename = "${path.module}/worker_key.pem"
  file_permission = "0600"
}

resource "aws_key_pair" "ec2_key" {
  key_name   = "ec2_key"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

resource "aws_instance" "ec2_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.ec2_key.key_name

  user_data = <<-EOF
              #!/bin/bash
              mkdir -p /home/ubuntu/.ssh
              echo "${tls_private_key.ec2_key.public_key_openssh}" > /home/ubuntu/.ssh/authorized_keys
              chown -R ubuntu:ubuntu /home/ubuntu/.ssh
              chmod 700 /home/ubuntu/.ssh
              chmod 600 /home/ubuntu/.ssh/authorized_keys
              EOF

  tags = {
    Name = var.instance_name
  }

   
  depends_on = [aws_key_pair.ec2_key]
}

output "worker_ip" {
  value = aws_instance.ec2_instance.public_ip
}