cd ingress-sec
# Desplegamos el gateway
kubectl apply -f deploy_waf.yaml
sleep 10

# Creamos los certificados TLS
openssl req -x509 -nodes -days 1000 -newkey rsa:2048 -keyout ingress.key -out ingress.crt -subj "/CN=php.internal/O=security"
kubectl create secret tls tls-cert --key ingress.key --cert ingress.crt -n front

# Escribir en /etc/hosts la ip y el dominio
#ip=$(hostname -I | awk '{print $1}')
ip=127.0.0.1
if grep -q "php.internal" /etc/hosts; then
    echo "Ya está el dominio php.internal en /etc/hosts"
else
    sudo sh -c 'echo "'$ip'  php.internal" >> /etc/hosts'
    echo "Se ha añadido el dominio php.internal a /etc/hosts"
fi

kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s

cd ..
