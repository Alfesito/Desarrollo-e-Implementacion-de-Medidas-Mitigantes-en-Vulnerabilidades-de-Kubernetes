#!/bin/bash
read -p "¿Vas a hacer uso Minikube? (s/n): " is_minikube

if [ "$is_minikube" == "s" ]; then
    minikube start --force
    minikube_status=$?
    if [ $minikube_status -ne 0 ]; then
        echo "Error al iniciar Minikube. Saliendo del script."
        exit 1
    fi
fi

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/cloud/deploy.yaml
kubectl apply -f php-page.yaml
kubectl apply -f grafana.yaml
kubectl create namespace back 2>/dev/null
kubectl apply -f backend.yaml

kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s

mysql_pod_status=$(kubectl get pods -n back | grep "^mysql-" | awk '{print $3}')
while [ "$mysql_pod_status" != "Running" ]; do
    mysql_pod_status=$(kubectl get pods -n back | grep "^mysql-" | awk '{print $3}')
    sleep 5
done

mysql_pod_name=$(kubectl get pods -n back | grep -e mysql | awk '{print $1}')
kubectl cp ./docker-images/mysql/init.sql "$mysql_pod_name":/tmp/init.sql -n back
kubectl exec -t "$mysql_pod_name" -n back -- bash -c 'mysql -u root -pp@ssword < /tmp/init.sql'
kubectl exec -t "$mysql_pod_name" -n back -- bash -c 'mysql -u root -pp@ssword < /tmp/init.sql'
kubectl exec -t "$mysql_pod_name" -n back -- rm /tmp/init.sql

ip=127.0.0.1
if grep -q "php.internal" /etc/hosts; then
    echo "Ya está el dominio php.internal en /etc/hosts"
else
    sudo sh -c 'echo "'$ip'  php.internal" >> /etc/hosts'
    echo "Se ha añadido el dominio php.internal a /etc/hosts"
fi

kubectl create ingress php-localhost --class=nginx --rule='php.internal/*=php-page:80' -n default
kubectl port-forward --namespace=ingress-nginx service/ingress-nginx-controller 8080:80
#minikube service --all

echo FIN