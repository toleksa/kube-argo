#!/bin/bash

. ./env ; METALLB_ADDRESSES=${METALLB_ADDRESSES:=`hostname -I | awk '{print $1"-"$1}'`} envsubst < kube-argo.yaml

