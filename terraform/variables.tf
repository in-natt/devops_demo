#Variables on UPPERCASE are allocated on tfvars
variable "AWS_ACCESS_KEY_ID" {
  description = "Access key for AWS"
  default     = "no_access_key_value_found"
}

variable "AWS_SECRET_ACCESS_KEY" {
  description = "Secret key for AWS"
  default     = "no_secret_key_value_found"
}

variable "aws_region" {
  description = "AWS region to use"
  default     = "us-east-1"
}

variable "my_tag" {
  description = "Default tag for this Demo"
  default     = "my_demo"
}

variable "ami" {
  default = "ami-0f9fc25dd2506cf6d"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "namespace" {
  default = "terraform"
}

variable "resource_tag_name" {
  default = "demo"
}

variable "key_name" {
  default = "demo_key"
}

variable "identifier" {
  description = "name RDS instance, if omitted, Terraform will assign a random, unique identifier"
  default     = "rds-demo"
}

#aws_db_instance - RDS
variable "db_port" {
  default = 3306
}

variable "DB_USERNAME" {
  description = "DB Username allocated on .tfvars"
  default     = ""
}

variable "DB_PASSWORD" {
  description = "DB Password allocated on .tfvars"
  default     = ""
}

variable "db_name" {
  description = "DB name to create when the DB instance is created"
  default     = "dbdemo"
}

variable "storage_type" {
  description = "Options 'standard'(magnetic), 'gp2'(general purpose SSD), 'io1' (provisioned IOPS SSD). Default is 'io1' if iops is specified, 'gp2' if not."
  default     = "gp2"
}
