#Install Git
until sudo apt install git-all -y; do
sleep 1
done

#Install Docker
until sudo  apt-get -y install docker.io; do
sleep 1
done

#Install AZ
curl -s "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x52E16F86FEE04B979B07E28DB02C46DF417A0893" | sudo apt-key add -
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

#Install Kubectl
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"

chmod +x ./kubectl

sudo mv ./kubectl /usr/local/bin/kubectl

#Install Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

