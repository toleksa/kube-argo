#!/bin/bash

kubectl delete secret kube-api-cert

#get CA from rke2.yaml config
#grep certificate-authority-data /etc/rancher/rke2/rke2.yaml | gawk '{ print $2 }' | base64 --decode > /root/CA.cer

. ./env

# generate kube-api-cert
#CMD="openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /$KUBERNETES_DOMAIN.key -out /$KUBERNETES_DOMAIN.crt -subj \"/CN=kube-api.${KUBERNETES_DOMAIN}/O=${KUBERNETES_DOMAIN}\" -addext \"subjectAltName = DNS:kube-api.${KUBERNETES_DOMAIN}\""
#echo $CMD
#eval $CMD

CMD="openssl genrsa -aes256 -passout pass:`hostname` -out /root/CA.key 4096"
echo $CMD
eval $CMD

CMD="openssl req -new -key /root/CA.key -passin pass:`hostname` -x509 -out /root/CA.cer -days 3650 -subj \"/C=AC/ST=AdbarCitadel/L=AdbarCitadel/O=AdbarCitadel CA/OU=kubernetes/CN=`hostname`\""
echo $CMD
eval $CMD

CMD="openssl req -new -nodes -newkey rsa:4096 -keyout /root/`hostname`.key -out /root/`hostname`.req -batch -subj \"/C=AC/ST=AdbarCitadel/L=AdbarCitadel/O=AdbarCitadel CA/OU=kubernetes/CN=`hostname`\" -reqexts SAN -config <(cat /etc/ssl/openssl.cnf <(printf \"[SAN]\nsubjectAltName=DNS:`hostname`\"))"
echo $CMD
eval $CMD

CMD="openssl x509 -req -in /root/`hostname`.req -CA /root/CA.cer -CAkey /root/CA.key -passin pass:`hostname` -CAcreateserial -out /root/`hostname`.crt -days 3650 -sha256 -extfile <(printf \"subjectAltName=DNS:`hostname`\")"
echo $CMD
eval $CMD

CMD="kubectl create secret tls kube-api-cert --key /root/`hostname`.key --cert /root/`hostname`.crt -n default"
echo $CMD
eval $CMD

