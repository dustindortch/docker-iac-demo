ARG VERSION=9.1.20230215
FROM rockylinux:${VERSION}

#START Prerequisites - yum
RUN yum check-update; \
    yum install -y gcc libffi-devel python39 epel-release; \
    yum install -y openssh-clients; \
    yum install -y expect; \
    yum install -y git; \
    yum install -y powershell; \
    yum install -y yum-utils; \
    yum install -y python3-devel python3-pip; \
    yum clean all
#END Prerequisites

#START Prerequisites - pip
RUN pip3 install --upgrade pip
#END Prerequisites - pip

#START Hashicorp tools - there is a link that needs to be removed for /usr/sbin/packer
ARG hashicorpRelease=RHEL
ARG versionTerraform=1.4.6-1
ARG versionPacker=1.8.7-1
ARG versionVault=1.13.2-1

RUN arch=$(arch | sed s/arm64/aarch64/ | sed s/amd64/x86_64/); \
    yum-config-manager --add-repo https://rpm.releases.hashicorp.com/${hashicorpRelease}/hashicorp.repo; \
    yum install -y terraform-${versionTerraform}.${arch}; \
    rm -f /usr/sbin/packer; \
    yum install -y packer-${versionPacker}.${arch}; \
    yum install -y vault-${versionVault}.${arch}
#END Hashicorp tools

#START Ansible tools
ARG versionAnsible=7.5.0

RUN pip install ansible==${versionAnsible}; \
    pip install ansible[azure]; \
    pip install pywinrm; \
    pip install netaddr; \
    pip install ipaddress; \
    pip install deepdiff; \
    pip install ansible-lint
#END Ansible tools

#START Platform tools
RUN arch=$(arch | sed s/arm64/aarch64/ | sed s/amd64/x86_64/); \
    rpm --import https://packages.microsoft.com/keys/microsoft.asc; \
    yum install -y https://packages.microsoft.com/config/rhel/9.0/packages-microsoft-prod.rpm; \
    yum install -y azure-cli; \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-${arch}.zip" -o "awscliv2.zip"; \
    yum install -y unzip; \
    unzip awscliv2.zip; \
    ./aws/install -i /usr/local/aws-cli -b /usr/local/bin; \
    aws --version
#END Platform tools

WORKDIR /wkd