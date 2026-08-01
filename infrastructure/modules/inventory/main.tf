# Local provisioner: renders the Ansible inventory from the EC2 instance
# IDs/IPs produced by the compute module. No manual editing of ansible/inventory
# is ever required - it is fully derived from Terraform state.
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/${var.output_path}"

  content = templatefile("${path.module}/../../templates/hosts.tpl", {
    master_id  = var.master_id
    master_ip  = var.master_ip
    worker_ids = var.worker_ids
    worker_ips = var.worker_ips
    key_name   = var.key_name
  })

  file_permission = "0644"
}
