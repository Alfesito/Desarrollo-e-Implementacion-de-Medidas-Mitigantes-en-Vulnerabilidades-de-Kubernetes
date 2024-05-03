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

kubectl apply -f grafana.yaml
kubectl apply -f php-page.yaml
kubectl create namespace back 2>/dev/null
kubectl apply -f backend.yaml

pod_name=$(kubectl get pods -n back | grep -e mysql | awk '{print $1}')
pod_status=$(kubectl get pods -n back "$pod_name" -o jsonpath='{.status.phase}')

while [ "$pod_status" != "Running" ]; do
    pod_status=$(kubectl get pods -n back "$pod_name" -o jsonpath='{.status.phase}')
    sleep 1

done

kubectl cp ./docker-images/mysql/init.sql "$pod_name":/tmp/init.sql -n back
kubectl exec -it "$pod_name" -n back -- bash -c 'mysql -u root -pp@ssword < /tmp/init.sql'
kubectl exec -it "$pod_name" -n back -- rm /tmp/init.sql

if [ "$is_minikube" == "s" ]; then
    echo "Habilitando IP externa para el servicio"
    minikube service --all
else
    php_page_ip=""
    php_page_port=""
    
    while [ "$php_page_ip" == "<pending>" ]; do
        php_page_ip=$(kubectl get svc php-page -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
        php_page_port=$(kubectl get svc php-page -o=jsonpath='{.spec.ports[0].targetPort}')
        sleep 2
    done

    echo "La IP externa del servicio php-page es: $(kubectl get svc php-page -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'):$php_page_port"
fi