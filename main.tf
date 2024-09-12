provider "aws" {
    region = "eu-central-1"
}

resource "aws_vpc" "BezogiaStgVpc" {
  cidr_block = "15.0.0.0/16"

  tags = {
    Name = "BezogiaStgVpc"
  }
}

resource "aws_internet_gateway" "IGWBezogiaStgVpc" {
  
  vpc_id = aws_vpc.BezogiaStgVpc.id
  tags = {
    Name = "IGWBezogiaStgVpc"
  }
}

resource "aws_subnet" "Public-Subnet-1" {
  vpc_id = aws_vpc.BezogiaStgVpc.id
  cidr_block = "15.0.0.0/20"
  availability_zone = "eu-central-1c"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public-Subnet-1"
  }
}

resource "aws_subnet" "Private-Subnet-1" {
  vpc_id = aws_vpc.BezogiaStgVpc.id
  cidr_block = "15.0.16.0/20"
  availability_zone = "eu-central-1c"
  tags = {
    Name = "Private-Subnet-1"
  }
}

resource "aws_route_table" "Public-Route-table" {
  vpc_id = aws_vpc.BezogiaStgVpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGWBezogiaStgVpc.id
  }

  tags = {
    Name = "Public-Route-Table"
  }
}


resource "aws_route_table_association" "Public-Routetable-Association" {
  subnet_id = aws_subnet.Public-Subnet-1.id
  route_table_id = aws_route_table.Public-Route-table.id
}

resource "aws_route_table" "Private-Route-Table" {
  vpc_id = aws_vpc.BezogiaStgVpc.id
  tags = {
    Name = "Private-Route-Table"
  }
}

resource "aws_route_table_association" "Private-Routetable-association" {
  subnet_id = aws_subnet.Private-Subnet-1.id
  route_table_id = aws_route_table.Private-Route-Table.id
}  

resource "tls_private_key" "RSA-key" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "Public-key" {
  public_key = tls_private_key.RSA-key.public_key_openssh
  key_name = "Bezogia-api-stg"

  provisioner "local-exec" {
    command = <<-EOT
    echo "${tls_private_key.RSA-key.private_key_pem}" > Bezogia-api-stg.pem
    EOT
  }
}

resource "aws_security_group" "Ec2_sg" {
  vpc_id = aws_vpc.BezogiaStgVpc.id

  ingress {
    from_port = 22
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "tcp"
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-Bezogia-EC2"
  }
}


resource "aws_instance" "Bezogia-Api-Stg" {
  instance_type = "t3.large"
  security_groups = [aws_security_group.Ec2_sg.id]
  ami = "ami-09222279fcca5c53d"
  subnet_id = aws_subnet.Public-Subnet-1.id
  associate_public_ip_address = false
  
  tags = {
    Name = "Bezogia-Api-Master-Stg"
  }

  root_block_device {
    volume_size = 100
    volume_type = "gp3"
    delete_on_termination = false
    tags = {
      Name = "Bezogia-Stg-block"
    }
  }

  user_data = <<-EOF
  #!/bin/bash
  yum install httpd -y
  systemctl start httpd
  systemctl enable httpd
  EOF 

  provisioner "local-exec" {
    command = "echo Instance is created"
  }

  }

  resource "aws_eip" "Elastic-IP-Master" {
    instance = aws_instance.Bezogia-Api-Stg.id

    tags = {
      Name = "Api-Stg-EIP"
    }
  }

  output "Api-Elastic-Ip" {
    value = aws_eip.Elastic-IP-Master.public_ip
  }