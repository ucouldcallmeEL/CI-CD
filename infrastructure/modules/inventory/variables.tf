variable "master_id" {
  type = string
}

variable "master_ip" {
  type = string
}

variable "worker_ids" {
  type = list(string)
}

variable "worker_ips" {
  type = list(string)
}

variable "key_name" {
  type = string
}

variable "output_path" {
  type        = string
  description = "Path (relative to repo root) to write the generated Ansible inventory to"
  default     = "../ansible/inventory/hosts.ini"
}
