############################
#    Terraform provider
############################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "ap-northeast-1"
}

############################
#    VPC
############################
resource "aws_vpc" "vpc_kattest" {
  cidr_block       = "172.16.0.0/16"
  instance_tenancy = "default"
}

resource "aws_internet_gateway" "gw_vpc_kattest" {
  vpc_id = aws_vpc.vpc_kattest.id
}

resource "aws_route_table" "route_kattest" {
  vpc_id = aws_vpc.vpc_kattest.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw_vpc_kattest.id
  }
}

############################
#    Management Subnet
############################
# Subnet
resource "aws_subnet" "subnet_mgmt" {
  vpc_id            = aws_vpc.vpc_kattest.id
  availability_zone = "ap-northeast-1d"
  cidr_block        = "172.16.213.0/24"

  depends_on        = [aws_internet_gateway.gw_vpc_kattest]
}

resource "aws_route_table_association" "subnet_mgmt_route_kattest" {
  subnet_id      = aws_subnet.subnet_mgmt.id
  route_table_id = aws_route_table.route_kattest.id
}

# SG
resource "aws_security_group" "sg_mgmt" {
  name        = "sg_mgmt"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.vpc_kattest.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

############################
#    EC2
############################

variable "public_key_path" {
  description = "SSH pubkey path."
}
# key pair
resource "aws_key_pair" "key_kattest" {
  key_name   = "kattest"
  public_key = file(var.public_key_path)
}
# EC2
resource "aws_instance" "sandbox_lin01" {
  # ap-northeast-1
  ami             = "ami-0992fc94ca0f1415a"
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.key_kattest.id
  private_ip      = "172.16.213.11"
  subnet_id       = aws_subnet.subnet_mgmt.id
  security_groups = [aws_security_group.sg_mgmt.id]
}

# EIP
resource "aws_eip" "eip_sandbox_lin01" {
  vpc = true

  instance                  = aws_instance.sandbox_lin01.id
  associate_with_private_ip = aws_instance.sandbox_lin01.private_ip
  depends_on                = [aws_internet_gateway.gw_vpc_kattest]
}