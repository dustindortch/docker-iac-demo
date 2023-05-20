terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

provider "aws" {
  # region = "us-east-1"
}

variable "ami_id" {
  default = "ami-0022f774911c1d690"
  type    = string
}

variable "instance_type" {
  default = "t2.micro"
  type    = string
}

variable "tags" {
  default = {
    "Name" = "ec2-demo-build"
  }
}

resource "aws_instance" "app_server" {
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = var.tags
}