variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name used as a prefix for all resources"
  type        = string
  default     = "microcloud"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "eks_cluster_version" {
  type    = string
  default = "3.6"
}

variable "node_instance_type" {
  type    = string
  default = "c7i-flex.large"
}

variable "tools_instance_type" {
  description = "Instance type used for Jenkins / Nexus / SonarQube boxes"
  type        = string
  default     = "m7i-flex.large"
}

variable "key_pair_name" {
  description = "Existing EC2 key pair name for SSH access"
  type        = string
  default     = "key_mumbai"
}
