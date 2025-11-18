variable "project_name"              { type = string }
variable "ubuntu_ami"                { type = string }
variable "key_pair_name"             { type = string }
variable "public_subnet_ids"         { type = list(string) }
variable "control_plane_sg_id"       { type = string }
variable "worker_sg_id"              { type = string }
variable "instance_profile_name"     { type = string }
variable "control_plane_instance_type" { type = string }
variable "worker_instance_type"        { type = string }
variable "worker_count"                { type = number }

locals {
  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Update
    apt-get update -y

    # Docker
    curl -fsSL https://get.docker.com | bash
    usermod -aG docker ubuntu

    # Kubernetes (v1.28)
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
    apt-get update -y
    apt-get install -y kubelet=1.28.0-00 kubeadm=1.28.0-00 kubectl=1.28.0-00
    apt-mark hold kubelet kubeadm kubectl

    # Disable swap (required for kubelet)
    sed -i '/ swap / s/^/#/' /etc/fstab
    swapoff -a

    # Enable IP forwarding / bridge
    cat <<EOT > /etc/modules-load.d/k8s.conf
    overlay
    br_netfilter
    EOT
    modprobe overlay
    modprobe br_netfilter

    cat <<EOT > /etc/sysctl.d/k8s.conf
    net.bridge.bridge-nf-call-iptables = 1
    net.ipv4.ip_forward = 1
    net.bridge.bridge-nf-call-ip6tables = 1
    EOT
    sysctl --system
  EOF
}

resource "aws_instance" "control_plane" {
  ami                         = var.ubuntu_ami
  instance_type               = var.control_plane_instance_type
  subnet_id                   = element(var.public_subnet_ids, 0)
  associate_public_ip_address = true
  key_name                    = var.key_pair_name
  vpc_security_group_ids      = [var.control_plane_sg_id]
  iam_instance_profile        = var.instance_profile_name
  user_data                   = local.user_data

  tags = { Name = "${var.project_name}-control-plane" }
}

resource "aws_instance" "workers" {
  count                       = var.worker_count
  ami                         = var.ubuntu_ami
  instance_type               = var.worker_instance_type
  subnet_id                   = element(var.public_subnet_ids, (count.index + 1) % length(var.public_subnet_ids))
  associate_public_ip_address = true
  key_name                    = var.key_pair_name
  vpc_security_group_ids      = [var.worker_sg_id]
  iam_instance_profile        = var.instance_profile_name
  user_data                   = local.user_data

  tags = { Name = "${var.project_name}-worker-${count.index}" }
}

output "control_plane_public_ip" { value = aws_instance.control_plane.public_ip }
output "worker_public_ips"       { value = [for i in aws_instance.workers : i.public_ip] }
