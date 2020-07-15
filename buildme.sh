#!/usr/bin/env bash
location=`pwd`
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

sudo dnf install -y grubby gcc g++ make cmake git containerd.io-1.2.13 docker-ce-19.03.11 docker-ce-cli-19.03.11

sudo grubby --update-kernel=ALL --args="systemd.unified_cgroup_hierarchy=0"
sudo mkdir /etc/docker
sudo cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable docker



CNI_VERSION="v0.8.2"
sudo mkdir -p /opt/cni/bin
sudo curl -L "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz" | sudo tar -C /opt/cni/bin -xz
DOWNLOAD_DIR=/usr/bin
CRICTL_VERSION="v1.17.0"
sudo curl -L "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz" | sudo tar -C $DOWNLOAD_DIR -xz
RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
sudo cd $DOWNLOAD_DIR
sudo curl -L --remote-name-all https://storage.googleapis.com/kubernetes-release/release/${RELEASE}/bin/linux/amd64/{kubeadm,kubelet,kubectl}
sudo chmod +x {kubeadm,kubelet,kubectl}
RELEASE_VERSION="v0.2.7"
sudo curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service
sudo mkdir -p /etc/systemd/system/kubelet.service.d
sudo curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

systemctl enable --now kubelet
sudo kubeadm init --pod-network-cidr=192.168.0.0/16

mkdir ${HOME}/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f https://docs.projectcalico.org/v3.14/manifests/calico.yaml
kubectl taint nodes --all node-role.kubernetes.io/master-


BINDIR="/usr/bin"
ECHO="echo -e"
$ECHO ''
DOMAIN="*.localdomain"
cd
mkdir certs
SRC_DIR="${HOME}/certs"
CRT_DIR="${SRC_DIR}/kubernetes"

kubectl get secret -o name basic-auth
username=cis
password=cis
docker run -it --rm bodom0015/htpasswd -b -c /dev/stdout $username $password
kubectl create secret generic basic-auth --from-literal=auth="cis:$apr1$XIvCwj2l$HXzqmzcmxbag0RpXZyuQa0"
mkdir -p ${CRT_DIR}
openssl genrsa 2048 > ${CRT_DIR}/${DOMAIN}.key
openssl req -new -x509 -nodes -sha1 -days 3650 -subj "/C=US/ST=IL/L=Champaign/O=NCSA/OU=NDS/CN=$DOMAIN" -key "${CRT_DIR}/${DOMAIN}.key" -out "${CRT_DIR}/${DOMAIN}.cert"
kubectl create secret generic cis-tls-secret --from-file=tls.crt="${CRT_DIR}/${DOMAIN}.cert" --from-file=tls.key="${CRT_DIR}/${DOMAIN}.key" --namespace=kube-system
kubectl create secret generic cis-tls-secret --from-file=tls.crt="${CRT_DIR}/${DOMAIN}.cert" --from-file=tls.key="${CRT_DIR}/${DOMAIN}.key"


kubectl create secret generic basic-auth --from-literal=auth="$(docker run -it --rm bodom0015/htpasswd -b -c /dev/stdout cis cis | tail -1)"

cd $location

./compose.sh build

kubectl apply -f platform/new/csa.yaml
kubectl apply -f platform/new/cloud9-ingress.yaml
kubectl apply -f platform/new/cloud9-service.yaml
kubectl apply -f platform/new/cloud9-deploy.yaml
kubectl apply -f platform/new/girder-namespace.yaml
kubectl apply -f platform/new/girder-csa.yaml
kubectl apply -f platform/new/girder-ingress.yaml
kubectl apply -f platform/new/girder-service.yaml
kubectl apply -f platform/new/girder-replication.yaml
kubectl apply -f platform/new/
