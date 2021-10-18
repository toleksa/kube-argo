#!/bin/bash

# install argo root app

helm template apps/ | kubectl apply -f -

# remove argo entry from helm
kubectl delete secret -l owner=helm,name=argo-cd
