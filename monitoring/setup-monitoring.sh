echo ...Creating namespace
kubectl create ns monitoring
echo 
echo ...Installing Prometheus and Grafana
echo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install -n monitoring monitoring --version="38.0.3" prometheus-community/kube-prometheus-stack
echo
echo ...Installing Kubernetes dashboard
echo
# install dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.5.0/aio/deploy/recommended.yaml
kubectl apply -f /workspaces/k8s-dev-v2/monitoring/dashboard-rbac.yaml
# install kustomize
curl --silent --location --remote-name \"https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v3.5.4/kustomize_kustomize.v3.5.4_linux_amd64" 
chmod a+x kustomize_kustomize.v3.5.4_linux_amd64 
sudo mv kustomize_kustomize.v3.5.4_linux_amd64 /usr/local/bin/kustomize
