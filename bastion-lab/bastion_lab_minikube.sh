#!/bin/bash

read -p "¿Vas a hacer uso Minikube? (s/n): " is_minikube

if [ "$is_minikube" == "s" ]; then
    minikube start
fi

# Creamos los distintos servicios y deployments, con su security context, para que no se ejecuten como root
kubectl create namespace back 2>/dev/null
kubectl apply -f backend-sec.yaml
kubectl create namespace front 2>/dev/null
kubectl apply -f grafana-sec.yaml
kubectl apply -f php-page-sec.yaml

# Esperamos a que el pod mysql este Running
mysql_pod_status=$(kubectl get pods -n back | grep "^mysql-" | awk '{print $3}')
if [ "$mysql_pod_status" != "Running" ];then
    while [ "$mysql_pod_status" != "Running" ]; do
        mysql_pod_status=$(kubectl get pods -n back | grep "^mysql-" | awk '{print $3}')
        sleep 5
    done
fi
mysql_pod_name=$(kubectl get pods -n back | grep -e mysql | awk '{print $1}')
kubectl cp ../kube-lab/docker-images/mysql/init.sql "$mysql_pod_name":/tmp/init.sql -n back
kubectl exec -t "$mysql_pod_name" -n back -- bash -c 'mysql -u root -pp@ssword < /tmp/init.sql'

# Aplicamos el ingress security
sh ./ingress-sec/gateway_waf.sh

# Aplicamos el controlador de acceso PodSecurity a todos los namespaces
kubectl label --overwrite ns --all pod-security.kubernetes.io/enforce=baseline pod-security.kubernetes.io/enforce-version=v1.30

kubectl create ingress php-localhost --class=nginx --rule='php.internal/*=php-page:80',tls=tls-cert -n front
#kubectl apply -f ./ingress-sec/ingress-https.yaml

kubectl exec -t "$mysql_pod_name" -n back -- bash -c 'mysql -u root -pp@ssword < /tmp/init.sql'
kubectl exec -t "$mysql_pod_name" -n back -- rm /tmp/init.sql

echo "La IP externa del servicio php-page es: https://php.internal:8443"
# Para crear un tunel con https
kubectl port-forward --namespace=ingress-nginx service/ingress-nginx-controller 8443:443
# Para crear un tunel con http
#kubectl port-forward --namespace=ingress-nginx service/ingress-nginx-controller 8080:80