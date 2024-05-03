#!/bin/bash
# Este script está creado para su uso con microk8s, si se utiliza otra herramienta, no se puede asegurar su total funcionamiento

snap start microk8s
microk8s start
alias kubectl='microk8s kubectl'
# Aplicamos el encription provider
sh ./encription-provider/encription_provider.sh
# Aplicamos el controlador de acceso AllwaysPullImages
#pgrep -an kubelite | grep -oP -- '--apiserver-args-file=\K[^ ]+'
sudo sed -i 's/--enable-admission-plugins.*/--enable-admission-plugins=EventRateLimits/' /var/snap/microk8s/6641/args/kube-apiserver
sudo sed -i 's/--enable-admission-plugins=EventRateLimits/--enable-admission-plugins=EventRateLimits,AllwaysPullImages/' /var/snap/microk8s/6641/args/kube-apiserver

# Creamos los distintos servicios y deployments, con su security context, para que no se ejecuten como root
kubectl create namespace default 2>/dev/null
kubectl apply -f grafana-sec.yaml
kubectl apply -f php-page-sec.yamls
kubectl create namespace back 2>/dev/null
kubectl apply -f backend-sec.yaml

# Aplicamos el ingress security
#sh ./ingress-sec/ingress_sec.sh

# Aplicamos el controlador de acceso PodSecurity
kubectl label --overwrite ns default pod-security.kubernetes.io/enforce=restricted pod-security.kubernetes.io/enforce-version=v1.30
kubectl label --overwrite ns back pod-security.kubernetes.io/enforce=baseline pod-security.kubernetes.io/enforce-version=v1.30

pod_name=$(kubectl get pods -n back | grep -e mysql | awk '{print $1}')
pod_status=$(kubectl get pods -n back "$pod_name" -o jsonpath='{.status.phase}')
while [ "$pod_status" != "Running" ]; do
    pod_status=$(kubectl get pods -n back "$pod_name" -o jsonpath='{.status.phase}')
    sleep 1
done
kubectl cp .init.sql "$pod_name":/tmp/init.sql -n back
kubectl exec -it "$pod_name" -n back -- bash -c 'mysql -u root -pp@ssword < /tmp/init.sql'
kubectl exec -it "$pod_name" -n back -- rm /tmp/init.sql

echo "La IP externa del servicio php-page es: $(curl ifconfig.me):80"
