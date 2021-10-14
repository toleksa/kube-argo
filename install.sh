#!/bin/bash

if [ ! -f ./env ]; then
  echo "env file is missing"
  exit 1
fi

. env

envsubst < kube-argo.yaml | kubectl apply -f -

