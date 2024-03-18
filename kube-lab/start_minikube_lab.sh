#!/bin/bash

minikube start
kubectl apply -f grafana.yaml
kubectl apply -f php-page.yaml
kubectl create namespace back 2>/dev/null
kubectl apply -f backend.yaml

sleep 2
pod_name=$(kubectl get pods -n back | grep -e mysql | awk '{print $1}')
pod_status=$(kubectl get pods -n back "$pod_name" -o jsonpath='{.status.phase}')

while [ "$pod_status" != "Running" ]; do
    sleep 1
    pod_status=$(kubectl get pods -n back "$pod_name" -o jsonpath='{.status.phase}' 2>/dev/null)
done

sleep 2
kubectl cp ./docker-images/mysql/init.sql "$pod_name":/tmp/init.sql -n back
kubectl exec -it "$pod_name" -n back -- bash -c 'mysql -u root -pp@ssword < /tmp/init.sql'
kubectl exec -it "$pod_name" -n back -- rm /tmp/init.sql

minikube service --all