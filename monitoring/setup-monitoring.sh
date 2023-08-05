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
echo
echo ---- TOKEN to use for logging into dashboard follows ---
echo 
/workspaces/k8s-dev-v2/monitoring/get-token.sh
echo
echo 
echo --------------------------------------------------------
echo
echo --- Grafana initial password follows ---
echo
kubectl get secret --namespace monitoring monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
echo
echo ----------------------------------------
echo
