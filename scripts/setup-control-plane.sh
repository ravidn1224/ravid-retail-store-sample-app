#!/bin/bash
set -e
set -o pipefail

echo "Setting up Kubernetes control plane..."

ADVERTISE_IP=$(ip route get 8.8.8.8 | awk '{print $7; exit}')
echo "Using advertise address: ${ADVERTISE_IP}"

echo "Initializing Kubernetes control plane..."
sudo kubeadm init \
  --apiserver-advertise-address="${ADVERTISE_IP}" \
  --control-plane-endpoint="${ADVERTISE_IP}" \
  --pod-network-cidr=192.168.0.0/16

echo "Configuring kubectl..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown "$(id -u):$(id -g)" $HOME/.kube/config

echo "Installing Calico CNI..."
curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.28.3/manifests/calico.yaml
kubectl apply -f calico.yaml

echo "Waiting for Calico to start..."
sleep 60
kubectl get pods -n kube-system

echo "Generating join command for worker nodes..."
kubeadm token create --print-join-command > /tmp/join-command.sh
chmod +x /tmp/join-command.sh

echo "Control plane setup completed."
echo "Join command is saved in /tmp/join-command.sh"