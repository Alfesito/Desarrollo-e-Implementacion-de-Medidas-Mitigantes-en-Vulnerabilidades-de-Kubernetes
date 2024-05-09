#!/bin/bash

read -p "¿Vas a hacer uso microk8s? (s/n): " is_microk8s

alias kubectl='microk8s kubectl'

if [ "$is_microk8s" == "s" ]; then
    snap start microk8s
    microk8s start
fi

# Creamos los distintos servicios y deployments, con su security context, para que no se ejecuten como root
microk8s kubectl create namespace back 2>/dev/null
microk8s kubectl apply -f backend-sec.yaml
microk8s kubectl create namespace front 2>/dev/null
microk8s kubectl apply -f grafana-sec.yaml
microk8s kubectl apply -f php-page-sec.yaml

# Esperamos a que el pod mysql este Running
mysql_pod_status=$(microk8s kubectl get pods -n back | grep "^mysql-" | awk '{print $3}')
if [ "$mysql_pod_status" != "Running" ];then
    while [ "$mysql_pod_status" != "Running" ]; do
        mysql_pod_status=$(microk8s kubectl get pods -n back | grep "^mysql-" | awk '{print $3}')
        sleep 5
    done
fi
mysql_pod_name=$(microk8s kubectl get pods -n back | grep -e mysql | awk '{print $1}')
microk8s kubectl cp ../kube-lab/docker-images/mysql/init.sql "$mysql_pod_name":/tmp/init.sql -n back
microk8s kubectl exec -t "$mysql_pod_name" -n back -- bash -c 'mysql -u root -pp@ssword < /tmp/init.sql'

if [ "$is_microk8s" == "s" ]; then
    # Aplicamos el controlador de acceso AllwaysPullImages
    dir_api=$(pgrep -an kubelite | grep -oP -- '--apiserver-args-file=\K[^ ]+')    sudo sed -i 's/--enable-admission-plugins.*/--enable-admission-plugins=EventRateLimits/' "$dir_api"
    sudo sed -i 's/--enable-admission-plugins=EventRateLimits/--enable-admission-plugins=AllwaysPullImages/' "$dir_api"

    # Aplicamos el encription provider
    sh ./encription-provider/encription_provider.sh
fi

# Aplicamos el ingress security
cd ingress-sec
microk8s kubectl apply -f deploy_waf.yaml
sleep 10
openssl req -x509 -nodes -days 1000 -newkey rsa:2048 -keyout ingress.key -out ingress.crt -subj "/CN=php.internal/O=security"
microk8s kubectl create secret tls tls-cert --key ingress.key --cert ingress.crt -n front
ip=127.0.0.1
if grep -q "php.internal" /etc/hosts; then
    echo "Ya está el dominio php.internal en /etc/hosts"
else
    sudo sh -c 'echo "'$ip'  php.internal" >> /etc/hosts'
    echo "Se ha añadido el dominio php.internal a /etc/hosts"
fi
microk8s kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s
cd ..

# Aplicamos el controlador de acceso PodSecurity a todos los namespaces
microk8s kubectl label --overwrite ns --all pod-security.kubernetes.io/enforce=baseline pod-security.kubernetes.io/enforce-version=v1.30

microk8s kubectl create ingress php-localhost --class=nginx --rule='php.internal/*=php-page:80',tls=tls-cert -n front
#microk8s kubectl apply -f ./ingress-sec/ingress-https.yaml

microk8s kubectl exec -t "$mysql_pod_name" -n back -- bash -c 'mysql -u root -pp@ssword < /tmp/init.sql'
microk8s kubectl exec -t "$mysql_pod_name" -n back -- rm /tmp/init.sql

echo "La IP externa del servicio php-page es: https://php.internal:8443"
# Para crear un tunel con https
microk8s kubectl port-forward --namespace=ingress-nginx service/ingress-nginx-controller 8443:443
# Para crear un tunel con http
#microk8s kubectl port-forward --namespace=ingress-nginx service/ingress-nginx-controller 8080:80