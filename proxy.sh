#!/usr/bin/env bash

if [ -n "$1" ] && [ -n "$2" ]; then
  export PUBLISHED_PORT=$1
  export KUBE_PORT=$2
  haproxy -f /proxy/kube-port-forward
  echo "Forwarding from port $PUBLISHED_PORT to $KUBE_PORT"
else
  echo "Please send two parameters: the exposed port and the kubectl port"
fi
