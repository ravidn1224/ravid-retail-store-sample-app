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


# sudo kubeadm join <CONTROL-PLANE-IP>:6443 --token <TOKEN> \
#     --discovery-token-ca-cert-hash <HASH>

echo "Worker node joined the cluster successfully!"
echo "You can verify this on the control plane with: kubectl get nodes"
