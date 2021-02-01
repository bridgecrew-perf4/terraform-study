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

resource "aws_vpc" "vpc-aws1" {
  cidr_block       = "192.168.37.0/24"
  instance_tenancy = "default"
}