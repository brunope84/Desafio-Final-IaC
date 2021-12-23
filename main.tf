# Criação da VPC
resource "aws_vpc" "brunope_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = "true"
  tags = {
    Name = "brunope_desafio_vpc"
  }
}

# Criação do Internet Gateway
resource "aws_internet_gateway" "brunope_gw" {
  vpc_id = aws_vpc.brunope_vpc.id
  tags = {
    Name = "brunope_desafio_gw"
  }
}

# Criação da Subnet Pública
resource "aws_subnet" "brunope_subnet" {
  vpc_id     = aws_vpc.brunope_vpc.id
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "brunope_desafio_public_subnet"
  }
}

# Criação da Route table
resource "aws_route_table" "brunope_rt" {
  vpc_id = aws_vpc.brunope_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.brunope_gw.id
  }
  tags = {
    Name = "brunope_desafio_public_rt"
  }
}
# Associação da Route table com a subnet pública
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.brunope_subnet.id
  route_table_id = aws_route_table.brunope_rt.id
}

# Criação do Security Group
variable "sg_ports" {
  type        = list(number)
  description = "Lista com as portas para o ingress e egress do sg"
  default     = [80, 443, 22]
}
resource "aws_security_group" "brunope_sg" {
  name        = "brunope_sg"
  description = "SG desafio final"
  vpc_id      = aws_vpc.brunope_vpc.id

  dynamic "ingress" {
    for_each = var.sg_ports
    iterator = porta
    content {
      from_port   = porta.value
      to_port     = porta.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  dynamic "egress" {
    for_each = var.sg_ports
    content {
      from_port   = egress.value
      to_port     = egress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  tags = {
    Name = "brunope_desafio_sg"
  }
}

# Criação da Instância
resource "aws_instance" "brunope_ec2" {
  ami                         = "ami-04902260ca3d33422"
  instance_type               = "t3.medium"
  key_name                    = "vockey"
  subnet_id                   = aws_subnet.brunope_subnet.id
  vpc_security_group_ids      = [aws_security_group.brunope_sg.id]
  associate_public_ip_address = "true"

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install -y nginx1.12",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx"
    ]

  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("./labsuser.pem")
    host        = self.public_ip
  }

  tags = {
    Name       = "ec2-brunope_desafio",
    Ambiente   = "Development",
    Time       = "Mackenzie"
    Applicacao = "Site"
    BU         = "Conta Digital"
  }
}

output "info_ec2_arn" {
  value = aws_instance.brunope_ec2.arn
}
output "info_ec2_public_ip" {
  value = aws_instance.brunope_ec2.public_ip
}
output "info_ec2_public_dns" {
  value = aws_instance.brunope_ec2.public_dns
}