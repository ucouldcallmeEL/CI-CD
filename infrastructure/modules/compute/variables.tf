variable "project_name" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "master_sg_id" {
  type = string
}

variable "worker_sg_id" {
  type = string
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

variable "key_name" {
  type        = string
  description = "Existing EC2 key pair name used for SSH / Ansible access"
}
