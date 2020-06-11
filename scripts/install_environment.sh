set -euo pipefail

source utils.sh

function install_libvirt() {
  if ! [ -x "$(command -v virsh)" ]; then
    echo "Installing libvirt..."
    dnf install -y libvirt libvirt-devel libvirt-daemon-kvm qemu-kvm
    systemctl enable --now libvirtd
  else
    echo "libvirt is already installed"
  fi
  
  sed -i -e 's/#LIBVIRTD_ARGS="--listen"/LIBVIRTD_ARGS="--listen"/g' /etc/sysconfig/libvirtd
  sed -i -e 's/#listen_tls/listen_tls/g' /etc/libvirt/libvirtd.conf
  sed -i -e 's/#listen_tcp/listen_tcp/g' /etc/libvirt/libvirtd.conf
  sed -i -e 's/#auth_tcp = "sasl"/auth_tcp = "none"/g' /etc/libvirt/libvirtd.conf
  sed -i -e 's/#tcp_port/tcp_port/g' /etc/libvirt/libvirtd.conf
  sed -i -e 's/#security_driver = "selinux"/security_driver = "none"/g' /etc/libvirt/qemu.conf
}

function install_runtime_container() {
  if ! [ -x "$(command -v docker)" ] && ! [ -x "$(command -v podman)" ]; then
    dnf install podman-1.6.4 -y
  elif [ -x "$(command -v podman)" ]; then
    dnf install podman-1.6.4 -y
  else
    echo "docker or podman is already installed"
  fi
}

function install_terraform() {
  wget `wget https://www.terraform.io/downloads.html -q -O - | grep -oP "(https://releases.hashicorp.com/terraform/.*linux_amd64\.zip)(?=\")" | head -n 1` && unzip terraform*.zip -d /usr/bin/ && rm -rf terraform*.zip
  wget https://dl.google.com/go/go1.13.4.linux-amd64.tar.gz && tar -C /usr/local -xf go1.13.4.linux-amd64.tar.gz && rm -f go1.13.4.linux-amd64.tar.gz
  mkdir -p ~/.terraform.d/plugins
  go get -v -u github.com/dmacvicar/terraform-provider-libvirt && cd ~/.terraform.d/plugins && go build -a -v github.com/dmacvicar/terraform-provider-libvirt && rm -rf ~/go
}

function install_aws() {
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && ./aws/install && rm -rf awscliv2.zip
}

function install_packages(){
  dnf install -y make python3 git jq bash-completion xinetd wget unzip
  systemctl enable --now xinetd
  pip3 install --no-cache-dir -r requirements.txt
}

function install_skipper() {
   pip3 install strato-skipper==1.20.0
}

install_packages
install_libvirt
install_runtime_container
install_skipper
systemctl restart libvirtd
touch ~/.gitconfig
install_terraform
install_aws
install_bm_client

chmod ugo+rx "$(dirname "$(pwd)")"
