[master]
${master_ip} ansible_host=${master_ip} ansible_user=ubuntu instance_id=${master_id}

[workers]
%{ for idx, ip in worker_ips ~}
${ip} ansible_host=${ip} ansible_user=ubuntu instance_id=${worker_ids[idx]}
%{ endfor ~}

[kubernetes:children]
master
workers

[all:vars]
ansible_ssh_private_key_file=~/.ssh/${key_name}.pem
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
