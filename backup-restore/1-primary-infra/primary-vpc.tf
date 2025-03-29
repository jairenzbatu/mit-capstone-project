# COPIED

# Primary Infrastructure VPC Configurations
# VPC configurations
resource "aws_vpc" "app_vpc" {
  provider   = aws.primary
  cidr_block = var.vpc_cidr

  tags = {
    Name = "app-vpc"
  }
}

# internet gateway configuration
resource "aws_internet_gateway" "igw" {
  provider = aws.primary
  vpc_id   = aws_vpc.app_vpc.id

  tags = {
    Name = "vpc-igw"
  }
}

# load balancer subnet
resource "aws_subnet" "public_alb_a_subnet" {
  provider                = aws.primary
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = var.public_alb_subnet_a_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.az_zone_a

  tags = {
    Name = "public-alb-a-subnet"
  }
}
resource "aws_subnet" "public_alb_b_subnet" {
  provider                = aws.primary
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = var.public_alb_subnet_b_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.az_zone_b

  tags = {
    Name = "public-alb-b-subnet"
  }
}

# app server subnet
resource "aws_subnet" "public_app_subnet_a" {
  provider                = aws.primary
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = var.public_app_subnet_a_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.az_zone_a

  tags = {
    Name = "public-subnet"
  }
}
resource "aws_subnet" "public_app_subnet_b" {
  provider                = aws.primary
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = var.public_app_subnet_b_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.az_zone_b

  tags = {
    Name = "public-subnet"
  }
}

# database server subnet
resource "aws_subnet" "rds_subnet_a" {
  provider                = aws.primary
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = var.public_rds_subnet_a_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.az_zone_a

  tags = {
    Name = "rds-subnet-a"
  }
}
resource "aws_subnet" "rds_subnet_b" {
  provider                = aws.primary
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = var.public_rds_subnet_b_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.az_zone_b

  tags = {
    Name = "rds-subnet-b"
  }
}

# vpc route table
resource "aws_route_table" "public_rt" {
  provider = aws.primary
  vpc_id   = aws_vpc.app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public_rt"
  }
}

# route table associations
resource "aws_route_table_association" "public_alb_a_rt_asso" {
  provider       = aws.primary
  subnet_id      = aws_subnet.public_alb_a_subnet.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "public_alb_b_rt_asso" {
  provider       = aws.primary
  subnet_id      = aws_subnet.public_alb_b_subnet.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "public_rt_a_asso" {
  provider       = aws.primary
  subnet_id      = aws_subnet.public_app_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "public_rt_b_asso" {
  provider       = aws.primary
  subnet_id      = aws_subnet.public_app_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "rds_a_rt_asso" {
  provider       = aws.primary
  subnet_id      = aws_subnet.rds_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "rds_b_rt_asso" {
  provider       = aws.primary
  subnet_id      = aws_subnet.rds_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Groups
resource "aws_security_group" "alb_sg" {
  provider    = aws.primary
  name        = "allow_http_on_alb"
  description = "Allow http inbound traffic"
  vpc_id      = aws_vpc.app_vpc.id

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTPS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_alb_http"
  }
}
resource "aws_security_group" "app_sg" {
  provider    = aws.primary
  name        = "allow_ssh_http_on_app"
  description = "Allow ssh http inbound traffic"
  vpc_id      = aws_vpc.app_vpc.id

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTPS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh_http_on_app"
  }
}
resource "aws_security_group" "rds_sg" {
  provider    = aws.primary
  name        = "allow_mysql"
  description = "Allow MySQL inbound traffic"
  vpc_id      = aws_vpc.app_vpc.id

  ingress {
    description = "MySQL traffic from anywhere"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_mysql"
  }
}