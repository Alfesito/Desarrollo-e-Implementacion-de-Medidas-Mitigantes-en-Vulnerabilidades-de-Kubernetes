kubectl run example-pod --image=nginx -l=app=nginx
# Exponer el servicio de php
kubectl expose pod example-pod nginx --port=80 --target-port=80 --name=example-svc
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/baremetal/deploy.yaml
# Creamos los certifiicados TLS
mkdir ingress
cd ingress
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ingress.key -out ingress.crt -subj "/CN=example.internal/O=security"
kubectl create secret tls tls-cert --key ingress.key --cert ingress.crt
kubectl get secret tls-cert -o yaml
kubectl apply -f ingress-https.yaml
#Escribir en /etc/hosts la ip y el dominio
kubectl get svc -n ingress-nginx
apt install net-tools
ifconfig eth0
curl http://example.internal:30429