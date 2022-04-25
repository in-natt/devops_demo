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

resource "aws_internet_gateway" "demo" {
  vpc_id = aws_vpc.demo.id
}

resource "aws_route_table" "demo" {
  vpc_id = aws_vpc.demo.id

  dynamic "route" {
    for_each = var.route

    content {
      cidr_block     = route.value.cidr_block
      gateway_id     = route.value.gateway_id
      instance_id    = route.value.instance_id
      nat_gateway_id = route.value.nat_gateway_id
    }
  }
}

resource "aws_route_table_association" "demo" {
  count = length(var.subnet_ids)

  subnet_id      = element(var.subnet_ids, count.index)
  route_table_id = aws_route_table.demo.id
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                  = "vpc-demo"
  cidr                  = "10.0.0.0/16"
  secondary_cidr_blocks = ["10.1.0.0/16", "0.0.0.0/0"]
  # resource_tag_name = var.resource_tag_name
  # namespace         = var.namespace
  # region            = var.aws_region

  #vpc_cidr = "10.0.0.0/16"
  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = true

  # route = [
  #   {
  #     cidr_block     = "0.0.0.0/0"
  #     gateway_id     = module.vpc.gateway_id
  #     instance_id    = null
  #     nat_gateway_id = null
  #   }
  # ]

  #subnet_ids = module.subnet_ec2.ids
  tags = {
    Name = var.my_tag
  }

  vpc_tags = {
    Name = "vpc-demo"
  }
}

locals {
  resource_name_prefix = "${var.namespace}-${var.resource_tag_name}"
}

resource "aws_instance" "demo" {
  ami                         = var.ami
  instance_type               = var.instance_type
  user_data                   = var.user_data
  subnet_id                   = var.subnet_id
  associate_public_ip_address = var.associate_public_ip_address
  key_name                    = aws_key_pair.demo.key_name
  monitoring                  = true
  vpc_security_group_ids      = var.vpc_security_group_ids

  iam_instance_profile = var.iam_instance_profile

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

  #resource_tag_name = var.resource_tag_name
  #namespace         = var.namespace
  #region            = var.region

  ami           = var.ami
  key_name      = "${local.resource_name_prefix}-ec2-key"
  instance_type = var.instance_type
  subnet_id     = module.subnet_ec2.ids[0]

  vpc_security_group_ids = [aws_security_group.ec2.id]
  # vpc_id = module.vpc.id

  tags = {
    Name = var.my_tag
  }
}

#EC2 SECURITY GROUP
resource "aws_security_group" "ec2" {
  name = "${local.resource_name_prefix}-ec2-sg"

  description = "EC2 security group (terraform-managed)"
  vpc_id      = module.vpc.id

  ingress {
    from_port   = var.rds_port
    to_port     = var.rds_port
    protocol    = "tcp"
    description = "MySQL"
    cidr_blocks = local.rds_cidr_blocks
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
}

#RDS
locals {
  rds_name_prefix = "${var.namespace}-${var.resource_tag_name}"
}

resource "aws_db_subnet_group" "demo" {
  name       = "${local.rds_name_prefix}-${var.identifier}-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_db_instance" "demo" {
  identifier = "${local.rds_name_prefix}-${var.identifier}"

  allocated_storage     = var.allocated_storage #in GB
  max_allocated_storage = 2
  db_subnet_group_name  = aws_db_subnet_group.demo.id
  engine                = "mysql"
  engine_version        = "5.7"
  instance_class        = "db.t3.micro"
  #mysql configuration
  name                 = "mydb"
  enable_dns_hostnames = true
  port                 = var.port
  username             = var.username
  password             = var.password
  db_name              = ""
  parameter_group_name = "default.mysql5.7"

  publicly_accessible = var.publicly_accessible
  storage_encrypted   = var.storage_encrypted
  storage_type        = var.storage_type
  skip_final_snapshot = true

  vpc_security_group_ids = ["${aws_security_group.demo.id}"]

  allow_major_version_upgrade = var.allow_major_version_upgrade
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade

  # final_snapshot_identifier = var.final_snapshot_identifier
  # snapshot_identifier       = var.snapshot_identifier
  # skip_final_snapshot       = var.skip_final_snapshot

  performance_insights_enabled = var.performance_insights_enabled
}

#DB PASSWORD GENERATED
resource "random_string" "password" {
  length  = 16
  special = false
}

#RDS SECURITY GROUP
resource "aws_security_group" "demo" {
  name = "${local.rds_name_prefix}-rds-sg"

  description = "RDS (terraform-managed)"
  vpc_id      = var.rds_vpc_id

  # Only MySQL in
  ingress {
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = var.sg_ingress_cidr_block
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.sg_egress_cidr_block
  }
}

###NEED TO ADD S3 RESOURCE