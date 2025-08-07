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
  file_permission = "0400"
}

resource "aws_key_pair" "ec2_key" {
  key_name   = "ec2_key"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

resource "aws_instance" "ec2_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.ec2_key.key_name

  tags = {
    Name = var.instance_name
  }

   provisioner "remote-exec" {
    inline = [
      "sudo apt update" 
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu" 
      private_key = tls_private_key.ec2_key.private_key_pem
      host        = self.public_ip
    }
  }

  depends_on = [aws_key_pair.ec2_key]
}

