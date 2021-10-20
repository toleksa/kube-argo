#!/bin/bash

set -euo pipefail 

if [ ! -f ./env ]; then
  echo "env file is missing"
  exit 1
fi

. ./env

helm repo add argo-cd https://argoproj.github.io/argo-helm
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

METALLB_ADDRESSES=${METALLB_ADDRESSES:=`hostname -I | awk '{print $1}'`} \
envsubst < kube-argo.yaml | kubectl apply -f -

# remove argocd entry from helm, now it's selfmanaged
kubectl delete secret -l owner=helm,name=argocd -n argocd

# cli
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd
IP=$(kubectl -n argocd get svc | grep "argocd-server " | gawk '{ print $3 }')
CMD="argocd login ${IP}:443 --username admin --password password --insecure"
eval $CMD
argocd app sync kube-argo
echo
echo "to login to argocd cli use this command:"
echo $CMD

