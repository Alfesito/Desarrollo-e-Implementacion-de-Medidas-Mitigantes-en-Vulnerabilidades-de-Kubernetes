#!/bin/bash
read -p "¿Vas a hacer uso Minikube? (s/n): " is_minikube

if [ "$is_minikube" == "s" ]; then
    minikube start
    minikube_status=$?
    if [ $minikube_status -ne 0 ]; then
        echo "Error al iniciar Minikube. Saliendo del script."
        exit 1
    fi
fi

kubectl apply -f php-page.yaml
kubectl apply -f grafana.yaml
kubectl create namespace back 2>/dev/null
kubectl apply -f backend.yaml

mysql_pod_status=$(kubectl get pods -n back | grep "^mysql-" | awk '{print $3}')
while [ "$mysql_pod_status" != "Running" ]; do
    mysql_pod_status=$(kubectl get pods -n back | grep "^mysql-" | awk '{print $3}')
    sleep 5
done

mysql_pod_name=$(kubectl get pods -n back | grep -e mysql | awk '{print $1}')
kubectl cp ./docker-images/mysql/init.sql "$mysql_pod_name":/tmp/init.sql -n back
kubectl exec -t "$mysql_pod_name" -n back -- bash -c 'mysql -u root -pp@ssword < /tmp/init.sql'
kubectl exec -t "$mysql_pod_name" -n back -- rm /tmp/init.sql

echo FIN