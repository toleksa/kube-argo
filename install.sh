#!/bin/bash

if [ ! -f ./env ]; then
  echo "env file is missing"
  exit 1
fi

. ./env

#CMD="helm install --create-namespace --namespace argocd --set server.ingres.enabled=true --set server.ingress.hosts=argocd.$KUBERNETES_DOMAIN argocd argo-cd/argo-cd"
CMD="helm install --create-namespace --namespace argocd argocd argo-cd/argo-cd"
echo $CMD
eval $CMD

# bcrypt(password)=$2a$10$rRyBsGSHK6.uc8fntPwVIuLVHgsAhAX7TcdrqW/RADU0uh7CaChLa
kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": {
    "admin.password": "$2a$10$rRyBsGSHK6.uc8fntPwVIuLVHgsAhAX7TcdrqW/RADU0uh7CaChLa",
    "admin.passwordMtime": "'$(date +%FT%T%Z)'"
  }}'

envsubst < kube-argo.yaml | kubectl apply -f -

# remove argocd entry from helm, now it's selfmanaged
kubectl delete secret -l owner=helm,name=argocd -n argocd

