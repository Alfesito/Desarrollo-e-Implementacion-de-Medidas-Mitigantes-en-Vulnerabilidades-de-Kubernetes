#!/bin/bash
# Este script está creado para su uso con microk8s, si se utiliza otra herramienta, no se puede asegurar su total funcionamiento

#snap start microk8s
#microk8s start
#alias kubectl='microk8s kubectl'
minikube start

# Aplicamos el ingress security
sh ./ingress-sec/gateway_waf.sh

# Aplicamos el controlador de acceso AllwaysPullImages
#pgrep -an kubelite | grep -oP -- '--apiserver-args-file=\K[^ ]+'
#sudo sed -i 's/--enable-admission-plugins.*/--enable-admission-plugins=EventRateLimits/' /var/snap/microk8s/6641/args/kube-apiserver
#sudo sed -i 's/--enable-admission-plugins=EventRateLimits/--enable-admission-plugins=AllwaysPullImages/' /var/snap/microk8s/6641/args/kube-apiserver
# Aplicamos el encription provider y reiniciamos el servicio kube-apiserver
#sh ./encription-provider/encription_provider.sh
# Creamos los distintos servicios y deployments, con su security context, para que no se ejecuten como root
kubectl create namespace back 2>/dev/null
kubectl apply -f backend-sec.yaml
kubectl create namespace front 2>/dev/null
kubectl apply -f grafana-sec.yaml
kubectl apply -f php-page-sec.yaml

mysql_pod_status=$(kubectl get pods -n back | grep "^mysql-" | awk '{print $3}')
if [ "$mysql_pod_status" != "Running" ];then
    while [ "$mysql_pod_status" != "Running" ]; do
        mysql_pod_status=$(kubectl get pods -n back | grep "^mysql-" | awk '{print $3}')
        sleep 1
    done
fi
mysql_pod_name=$(kubectl get pods -n back | grep -e mysql | awk '{print $1}')
kubectl exec -t "$mysql_pod_name" -n back -- bash -c 'apt-get install mysql-server'
kubectl cp ./data/init.sql "$mysql_pod_name":/tmp/init.sql -n back
kubectl exec -t "$mysql_pod_name" -n back -- bash -c 'mysql -u root -pp@ssword < /tmp/init.sql'
kubectl exec -t "$mysql_pod_name" -n back -- rm /tmp/init.sql

# Aplicamos el controlador de acceso PodSecurity
#kubectl label --overwrite ns default pod-security.kubernetes.io/enforce=restricted pod-security.kubernetes.io/enforce-version=v1.30
#kubectl label --overwrite ns back pod-security.kubernetes.io/enforce=baseline pod-security.kubernetes.io/enforce-version=v1.30

kubectl create ingress php-localhost --class=nginx --rule='php.internal/*=php-page:80' -n front
echo "La IP externa del servicio php-page es: http://php.internal:8080"
kubectl port-forward --namespace=ingress-nginx service/ingress-nginx-controller 8080:80