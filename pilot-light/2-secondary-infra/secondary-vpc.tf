# Secondary Infrastructure VPC Resources

# load balancer subnet
resource "aws_subnet" "secondary_public_alb_a_subnet" {
  provider                = aws.secondary
  vpc_id                  = var.secondary_vpc
  cidr_block              = var.secondary_public_alb_subnet_a_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.secondary_az_zone_a

  tags = {
    Name = "secondary_public-alb-a-subnet"
  }
}
resource "aws_subnet" "secondary_public_alb_b_subnet" {
  provider                = aws.secondary
  vpc_id                  = var.secondary_vpc
  cidr_block              = var.secondary_public_alb_subnet_b_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.secondary_az_zone_b

  tags = {
    Name = "secondary_public-alb-b-subnet"
  }
}

# app server subnet
resource "aws_subnet" "secondary_public_app_subnet_a" {
  provider                = aws.secondary
  vpc_id                  = var.secondary_vpc
  cidr_block              = var.secondary_public_app_subnet_a_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.secondary_az_zone_a

  tags = {
    Name = "secondary_public-subnet"
  }
}
resource "aws_subnet" "secondary_public_app_subnet_b" {
  provider                = aws.secondary
  vpc_id                  = var.secondary_vpc
  cidr_block              = var.secondary_public_app_subnet_b_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.secondary_az_zone_b

  tags = {
    Name = "secondary_public-subnet"
  }
}

# route table associations
resource "aws_route_table_association" "secondary_public_alb_a_rt_asso" {
  provider       = aws.secondary
  subnet_id      = aws_subnet.secondary_public_alb_a_subnet.id
  route_table_id = var.secondary_public_rt
}
resource "aws_route_table_association" "secondary_public_alb_b_rt_asso" {
  provider       = aws.secondary
  subnet_id      = aws_subnet.secondary_public_alb_b_subnet.id
  route_table_id = var.secondary_public_rt
}
resource "aws_route_table_association" "secondary_public_rt_a_asso" {
  provider       = aws.secondary
  subnet_id      = aws_subnet.secondary_public_app_subnet_a.id
  route_table_id = var.secondary_public_rt
}
resource "aws_route_table_association" "secondary_public_rt_b_asso" {
  provider       = aws.secondary
  subnet_id      = aws_subnet.secondary_public_app_subnet_b.id
  route_table_id = var.secondary_public_rt
}

# Security Groups
resource "aws_security_group" "secondary_alb_sg" {
  provider    = aws.secondary
  name        = "secondary_allow_http_on_alb"
  description = "Allow http inbound traffic"
  vpc_id      = var.secondary_vpc

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
    Name = "secondary_allow_alb_http"
  }
}
resource "aws_security_group" "secondary_app_sg" {
  provider    = aws.secondary
  name        = "secondary_allow_ssh_http_on_app"
  description = "Allow ssh http inbound traffic"
  vpc_id      = var.secondary_vpc

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
    Name = "secondary_allow_ssh_http_on_app"
  }
}