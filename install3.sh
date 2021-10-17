#!/bin/bash

# install argo root app

helm template apps/ | kubectl apply -f -

