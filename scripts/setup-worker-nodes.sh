#!/bin/bash
set -e
set -o pipefail

echo "Setting up Kubernetes worker node..."

if ! command -v kubeadm >/dev/null; then
  echo "Kubernetes tools not found. Run install-prerequisites.sh first."
  exit 1
fi

echo "To join the cluster, paste the kubeadm join command from the control plane."
echo "Example:"
echo "sudo kubeadm join <control-plane-ip>:6443 --token <token> --discovery-token-ca-cert-hash <hash>"
echo ""

read -p "Enter the full kubeadm join command: " JOIN_CMD

echo "Joining the cluster..."
sudo $JOIN_CMD

echo "Worker node setup complete."
echo "Verify on the control plane using: kubectl get nodes"