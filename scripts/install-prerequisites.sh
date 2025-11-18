#!/bin/bash
set -e
set -o pipefail

echo "Installing prerequisites for Kubernetes v1.34 and Docker Engine (official repositories)..."


echo "Updating system packages..."
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl gpg lsb-release software-properties-common


echo "Installing Docker Engine (official Docker documentation)..."

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc


echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl enable docker
sudo systemctl start docker

echo "Configuring Docker daemon..."
sudo mkdir -p /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": { "max-size": "100m" },
  "storage-driver": "overlay2"
}
EOF

sudo systemctl daemon-reexec
sudo systemctl restart docker
sudo usermod -aG docker ubuntu || true


echo "🔌 Installing cri-dockerd..."
sudo apt-get install -y wget git

VER=$(curl -s https://api.github.com/repos/Mirantis/cri-dockerd/releases/latest | grep tag_name | cut -d '"' -f 4)
wget -q https://github.com/Mirantis/cri-dockerd/releases/download/${VER}/cri-dockerd-${VER#v}.amd64.tgz
sudo tar xzf cri-dockerd-${VER#v}.amd64.tgz -C /usr/local/bin/
sudo mv /usr/local/bin/cri-dockerd/cri-dockerd /usr/bin/
sudo rm -rf cri-dockerd-${VER#v}.amd64.tgz /usr/local/bin/cri-dockerd

sudo tee /etc/systemd/system/cri-docker.service >/dev/null <<EOF
[Unit]
Description=CRI Interface for Docker
After=network.target docker.service
Requires=docker.service

[Service]
ExecStart=/usr/bin/cri-dockerd --container-runtime-endpoint unix:///var/run/cri-dockerd.sock --network-plugin=cni
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/cri-docker.socket >/dev/null <<EOF
[Unit]
Description=CRI Docker Socket for the API
PartOf=cri-docker.service

[Socket]
ListenStream=/var/run/cri-dockerd.sock

[Install]
WantedBy=sockets.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable cri-docker.service
sudo systemctl enable --now cri-docker.socket
sudo systemctl start cri-docker.service

echo "🧩 Installing Kubernetes v1.34 components (kubeadm, kubelet, kubectl)..."

sudo mkdir -p -m 755 /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable --now kubelet

echo "🧠 Configuring kernel modules and sysctl..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

echo "💾 Disabling swap..."
sudo sed -i '/ swap / s/^/#/' /etc/fstab
sudo swapoff -a

echo "🔍 Verifying installation..."
docker --version
sudo systemctl status docker --no-pager
cri-dockerd --version
kubeadm version
kubectl version --client
kubelet --version

echo "install-prerequisites.sh completed successfully!"
