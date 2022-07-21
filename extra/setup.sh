echo
echo ...Pulling needed images
echo
# prepull images for custom apps
kubectl apply -f ~/beyond-k8s/extra/daemonset-prepull2.yaml
echo
echo ...Installing Istio
echo
# install istio
# ref: https://istio.io/latest/docs/setup/getting-started/
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
export PATH=$PWD/bin:$PATH
istioctl install --set profile=demo -y
echo
echo ...Installing argocd
echo
# install argocd
# ref: https://argo-cd.readthedocs.io/en/stable/getting_started/
kubectl create ns argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo chmod +x /usr/local/bin/argocd
echo
echo ...Installing tekton
echo
# install tekton
# ref: https://tekton.dev/docs/getting-started/tasks/
kubectl apply --filename \
https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
# ref: https://tekton.dev/docs/dashboard/install/
kubectl apply --filename https://storage.googleapis.com/tekton-releases/dashboard/latest/tekton-dashboard-release.yaml
# ref: https://github.com/tektoncd/cli
curl -LO https://github.com/tektoncd/cli/releases/download/v0.24.0/tektoncd-cli-0.24.0_Linux-64bit.deb
sudo dpkg -i tektoncd-cli-0.24.0_Linux-64bit.deb
echo
echo ...Getting initial ArgoCD password
echo
# dump out the initial argocd password
echo
echo ArgoCD password follows:
echo
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
