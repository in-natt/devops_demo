#COMMON VARIABLES USE LOWERCASE
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

