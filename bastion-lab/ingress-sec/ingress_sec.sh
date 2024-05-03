# Descargamos el gateway
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/baremetal/deploy.yaml
# Creamos los certificados TLS
cd ingress-sec
openssl req -x509 -nodes -days 1000 -newkey rsa:2048 -keyout ingress.key -out ingress.crt -subj "/CN=php.internal/O=security"
kubectl create secret tls tls-cert --key ingress.key --cert ingress.crt
#kubectl get secret tls-cert -o yaml
kubectl apply -f ingress-https.yaml
cd ..
# Escribir en /etc/hosts la ip y el dominio
ip=$(hostname -I | awk '{print $1}')
if grep -q "php.internal" /etc/hosts; then
    sudo sed -i '/php\.internal/d' /etc/hosts
fi
sudo sh -c 'echo "'$ip'  php.internal" >> /etc/hosts'
echo "Se ha añadido el dominio php.internal a /etc/hosts"

echo 'curl http://php.internal:30429'