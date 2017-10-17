FROM eeacms/cloud9:latest

ENV K8S_VERSION="1.5.2"

# Install kubectl binary
ADD https://storage.googleapis.com/kubernetes-release/release/v${K8S_VERSION}/bin/linux/amd64/kubectl /usr/bin/kubectl
RUN chmod +x /usr/bin/kubectl

# Install dependency for Docker
RUN apt-get update && apt-get install -y libltdl7 && rm -rf /var/lib/apt/lists/*