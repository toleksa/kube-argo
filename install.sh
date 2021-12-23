#!/bin/bash

. ~/.bashrc

set -euo pipefail 

if [ ! -f ./env ]; then
  echo "env file is missing"
  exit 1
fi

. ./env

#dns update
HOST="${KUBERNETES_DOMAIN}."
IP=`hostname -I | cut -d' ' -f1`
TTL="60"
RECORD=" $HOST $TTL A $IP"
echo "
server $EXTERNAL_DNS_RFC2136_HOST
zone $EXTERNAL_DNS_RFC2136_ZONE
debug
update add $RECORD
show
send" | nsupdate -y hmac-sha256:externaldns-key:${EXTERNAL_DNS_RFC2136_TSIGSECRET}

echo "Waiting for kubernetes to start"
until kubectl get nodes | grep `hostname` | grep " Ready " ; do
  sleep 5s
  echo -n .
done
echo ""
kubectl get nodes
echo ""

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

# install kube-argo app
. ./env ; METALLB_ADDRESSES=${METALLB_ADDRESSES:=`hostname -I | awk '{print $1"-"$1}'`} envsubst < kube-argo.yaml | kubectl apply -f -

# remove argocd entry from helm, now it's selfmanaged
kubectl delete secret -l owner=helm,name=argocd -n argocd

# argo cli
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd

# argo cli login and credentials
IP=$(kubectl -n argocd get svc | grep "argocd-server " | gawk '{ print $3 }')
CMD="argocd login ${IP}:443 --username admin --password password --insecure"
#eval $CMD      #this fails, needs to wait till argo is up
echo
echo "to login to argocd cli use this command:"
echo $CMD
echo "argocd app sync kube-argo"

