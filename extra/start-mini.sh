sudo minikube delete
curl -Lo minikube https://storage.googleapis.com/minikube/releases/v1.26.0/minikube-linux-amd64 && chmod +x minikube && sudo cp minikube /usr/local/bin/ && rm minikube
sudo minikube start --vm-driver=none --kubernetes-version=1.23.0
sudo mv /home/diyuser3/.kube /home/diyuser3/.minikube $HOME
sudo chown -R $USER $HOME/.kube $HOME/.minikube


