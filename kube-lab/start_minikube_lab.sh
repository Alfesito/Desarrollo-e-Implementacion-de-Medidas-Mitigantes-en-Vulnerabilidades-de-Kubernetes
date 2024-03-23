#!/bin/bash

minikube start
kubectl apply -f grafana.yaml
kubectl apply -f php-page.yaml
kubectl create namespace back 2>/dev/null
kubectl apply -f backend.yaml

pod_name=$(kubectl get pods -n back | grep -e mysql | awk '{print $1}')
pod_status=$(kubectl get pods -n back "$pod_name" -o jsonpath='{.status.phase}')
echo "$pod_status"

while [ "$pod_status" != "Running" ]; do
    sleep 3
    pod_status=$(kubectl get pods -n back "$pod_name" -o jsonpath='{.status.phase}' 2>/dev/null)
done

kubectl cp ./docker-images/mysql/init.sql "$pod_name":/tmp/init.sql -n back
kubectl exec -it "$pod_name" -n back -- bash -c 'mysql -u root -pp@ssword < /tmp/init.sql'
kubectl exec -it "$pod_name" -n back -- rm /tmp/init.sql

echo Fin

#minikube service --all
