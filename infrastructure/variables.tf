variable "project_name" {
  type    = string
  default = "weather-app-k8s"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "azs" {
  type        = list(string)
  description = "At least 2 AZs, required by the ALB"
  default     = ["us-east-1a", "us-east-1b"]
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "admin_cidr" {
  type        = string
  description = "Your IP in CIDR form (x.x.x.x/32), allowed to SSH. Never set this to 0.0.0.0/0."
}

variable "key_name" {
  type        = string
  description = "Existing EC2 key pair name"
}

variable "instance_type_master" {
  type    = string
  default = "t3.medium"
}

variable "instance_type_worker" {
  type    = string
  default = "t3.medium"
}

variable "worker_count" {
  type    = number
  default = 2
}

variable "node_ports" {
  type        = list(number)
  description = "NodePort(s) (>30000) the deployed Service is exposed on; ALB listens/forwards on these"
  default     = [30080]
}
