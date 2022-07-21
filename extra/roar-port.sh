 export POD_NAME=$(kubectl get pods --namespace $1 -l "app=roar-web" -o jsonpath="{.items[0].metadata.name}")
  kubectl port-forward $POD_NAME $2:8080 --namespace $1

