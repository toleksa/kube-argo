#!/bin/bash

kubectl delete secret kube-api-cert

# generate kube-api-cert
CMD="openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /$KUBERNETES_DOMAIN.key -out /$KUBERNETES_DOMAIN.crt -subj \"/CN=kube-api.${KUBERNETES_DOMAIN}/O=${KUBERNETES_DOMAIN}\" -addext \"subjectAltName = DNS:kube-api.${KUBERNETES_DOMAIN}\""
echo $CMD
eval $CMD

CMD="kubectl create secret tls kube-api-cert --key /$KUBERNETES_DOMAIN.key --cert /$KUBERNETES_DOMAIN.crt -n default"
echo $CMD
eval $CMD


