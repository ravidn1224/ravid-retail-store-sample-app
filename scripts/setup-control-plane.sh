#!/bin/bash
set -e
set -o pipefail

echo "Setting up Kubernetes control plane with Calico networking..."

ADVERTISE_IP=$(ip route get 8.8.8.8 | awk '{print $7; exit}')
echo "Using advertise address: ${ADVERTISE_IP}"


echo "Initializing Kubernetes control-plane node..."
sudo kubeadm init \
  --apiserver-advertise-address="${ADVERTISE_IP}" \
  --control-plane-endpoint="${ADVERTISE_IP}" \
  --pod-network-cidr=192.168.0.0/16 \
  --cri-socket unix:///var/run/cri-dockerd.sock

echo "kubeadm init completed successfully!"

echo "Configuring kubectl for user $(whoami)..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown "$(id -u):$(id -g)" $HOME/.kube/config

echo "Checking cluster-info..."
kubectl cluster-info
echo "Installing Calico CNI plugin..."
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.0/manifests/tigera-operator.yaml

echo "Applying Calico custom resources..."
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.0/manifests/custom-resources.yaml

echo "Waiting for Calico pods to start..."
sleep 60
kubectl get pods -n calico-system

echo "🔑 Generating join command for worker nodes..."
kubeadm token create --print-join-command > /tmp/join-command.sh
chmod +x /tmp/join-command.sh

echo "✅ Control-plane setup complete!"
echo "👉 Run the following command on each worker node (with sudo):"
echo ""
cat /tmp/join-command.sh
echo "    --cri-socket unix:///var/run/cri-dockerd.sock"
echo ""
echo "💡 Example:"
echo "sudo $(cat /tmp/join-command.sh) --cri-socket unix:///var/run/cri-dockerd.sock"
