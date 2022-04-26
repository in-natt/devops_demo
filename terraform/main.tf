#START
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.7.0"
    }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY
}

# CREATE VPC

resource "aws_vpc" "demo" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.demo.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "sub-1"
  }
  #FOR EC2
}

resource "aws_subnet" "subnet-2" {
  vpc_id     = aws_vpc.demo.id
  cidr_block = "10.0.2.0/24"
  tags = {
    Name = "sub-2"
  }
  #FOR RDS
}

resource "aws_subnet" "subnet-3" {
  vpc_id     = aws_vpc.demo.id
  cidr_block = "10.0.3.0/24"
  tags = {
    Name = "sub-3"
  }
  #FOR RDS
}
resource "aws_internet_gateway" "demo" {
  vpc_id = aws_vpc.demo.id
  tags = {
    Name = var.my_tag
  }
}

resource "aws_route_table" "demo" {
  vpc_id = aws_vpc.demo.id
  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = aws_internet_gateway.demo.id
  }
  tags = {
    Name = var.my_tag
  }
}

resource "aws_route_table_association" "sub-1" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.demo.id
}

resource "aws_route_table_association" "sub-2" {
  gateway_id     = aws_internet_gateway.demo.id
  route_table_id = aws_route_table.demo.id
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                  = "vpc-demo"
  cidr                  = "10.0.0.0/16"
  secondary_cidr_blocks = ["10.1.0.0/16", "10.1.0.0/28"]

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Name = var.my_tag
  }

  vpc_tags = {
    Name = "vpc-demo"
  }
}

#EC2 SECURITY GROUP
resource "aws_security_group" "ec2" {
  name = "${local.resource_name_prefix}-ec2-sg"

  description = "EC2 security group (terraform-managed)"
  vpc_id      = aws_vpc.demo.id

  ingress {
    #DB CONFIG PORT ##check variables
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    description = "MySQL"
    cidr_blocks = ["10.0.2.0/28"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    description = "Telnet"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "HTTP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    description = "HTTPS"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.my_tag
  }
}
locals {
  resource_name_prefix = "${var.namespace}-${var.resource_tag_name}"
}

resource "aws_instance" "demo" {
  ami           = var.ami
  instance_type = var.instance_type
  #user_data                   = var.user_data
  subnet_id = aws_subnet.subnet-1.id
  #associate_public_ip_address = var.associate_public_ip_address
  key_name               = aws_key_pair.demo.key_name
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.ec2.id]
  #iam_instance_profile = var.iam_instance_profile

  tags = {
    Name = var.my_tag
  }
}

resource "aws_eip" "demo" {
  vpc      = true
  instance = aws_instance.demo.id
}

resource "tls_private_key" "demo" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "demo" {
  key_name   = var.key_name
  public_key = tls_private_key.demo.public_key_openssh
}

module "ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  ami                    = var.ami
  key_name               = "${local.resource_name_prefix}-ec2-key"
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet-1.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  tags = {
    Name = var.my_tag
  }
}

#RDS SECURITY GROUP
resource "aws_security_group" "rds" {
  name = "${local.rds_name_prefix}-rds-sg"

  description = "RDS (terraform-managed)"
  vpc_id      = aws_vpc.demo.id

  # Only MySQL in
  ingress {
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = ["10.0.2.0/28"]
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.3.0/24"]
  }

  tags = {
    Name = "sub-2"
  }
}

#RDS
locals {
  rds_name_prefix = "${var.namespace}-${var.resource_tag_name}"
}

resource "aws_db_subnet_group" "demo" {
  name       = "${local.rds_name_prefix}-${var.identifier}-subnet-group"
  subnet_ids = ["aws_subnet.subnet-2.id", "aws_subnet.subnet-3.id"]

  tags = {
    Name = "My DB sub-2 group"
  }
}

resource "aws_db_instance" "rds-demo" {
  identifier = "${local.rds_name_prefix}-${var.identifier}"

  allocated_storage = 1
  #max_allocated_storage = 2 //AUTOSCALING
  engine         = "mysql"
  engine_version = "5.7"
  instance_class = "db.t3.micro"
  #name                 = "dbdemo"
  username             = var.DB_USERNAME
  password             = var.DB_PASSWORD
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  #enable_dns_hostnames = true
  port                 = var.db_port
  db_name              = var.db_name
  db_subnet_group_name = aws_db_subnet_group.demo.id
  #publicly_accessible  = var.publicly_accessible
  #storage_encrypted   = var.storage_encrypted
  storage_type           = var.storage_type
  vpc_security_group_ids = [aws_security_group.rds.id]
  # allow_major_version_upgrade = var.allow_major_version_upgrade
  # auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  #performance_insights_enabled = true
}

#DB PASSWORD GENERATED
resource "random_string" "password" {
  length  = 16
  special = false
}



###NEED TO ADD S3 RESOURCE
