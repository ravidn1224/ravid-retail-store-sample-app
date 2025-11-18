#!/bin/bash
set -e
set -o pipefail

echo "Setting up Kubernetes worker node..."


if ! command -v docker &>/dev/null; then
  echo "Installing Docker..."
  sudo apt-get update -y
  sudo apt-get install -y ca-certificates curl gnupg apt-transport-https
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo \"${UBUNTU_CODENAME:-$VERSION_CODENAME}\") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo systemctl enable docker
  sudo systemctl start docker
else
  echo "Docker is already installed."
fi


if ! command -v kubeadm &>/dev/null; then
  echo "Installing kubeadm, kubelet, and kubectl..."
  sudo mkdir -p -m 755 /etc/apt/keyrings
  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' \
    | sudo tee /etc/apt/sources.list.d/kubernetes.list
  sudo apt-get update -y
  sudo apt-get install -y kubelet kubeadm kubectl
  sudo apt-mark hold kubelet kubeadm kubectl
  sudo systemctl enable --now kubelet
else
  echo "kubeadm and kubelet are already installed."
fi


echo "Joining the Kubernetes cluster..."


sudo kubeadm join 10.0.1.138:6443 --token g68ely.m4c8th3d4iabs7d7 \
        --discovery-token-ca-cert-hash sha256:f03f109bd1150ba1697744bc8b25a6134f71c1c196fc8b49a1db98afb14810b8

echo "Worker node joined the cluster successfully!"
echo "You can verify this on the control plane with: kubectl get nodes"
