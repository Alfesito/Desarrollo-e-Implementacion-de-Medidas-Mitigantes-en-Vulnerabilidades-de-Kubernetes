# Solicita al usuario si va a usar Minikube
$is_minikube = Read-Host "¿Vas a hacer uso Minikube? (s/n)"

# Verifica si el usuario va a usar Minikube
if ($is_minikube -eq "s") {
    minikube start --force
    $minikube_status = $LASTEXITCODE
    if ($minikube_status -ne 0) {
        Write-Host "Error al iniciar Minikube. Saliendo del script."
        exit 1
    }
}

# Aplica los archivos de configuración con kubectl
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/cloud/deploy.yaml
kubectl apply -f php-page.yaml
kubectl apply -f grafana.yaml
kubectl create namespace back 2>$null
kubectl apply -f backend.yaml

# Espera hasta que el controlador de ingress-nginx esté listo
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s

# Comprueba el estado del pod de MySQL
$mysql_pod_status = ""
while ($mysql_pod_status -ne "Running") {
    $mysql_pod_status = kubectl get pods -n back | Select-String "^mysql-" | ForEach-Object { $_.Line.Split(" ")[2] }
    Start-Sleep -Seconds 5
}

# Obtiene el nombre del pod de MySQL
$mysql_pod_name = kubectl get pods -n back | Select-String "^mysql-" | ForEach-Object { $_.Line.Split(" ")[0] }

# Copia el archivo init.sql al pod de MySQL y ejecuta el script SQL
kubectl cp ./docker-images/mysql/init.sql "$mysql_pod_name":/tmp/init.sql -n back
kubectl exec -t "$mysql_pod_name" -n back -- bash -c 'mysql -u root -pp@ssword < /tmp/init.sql'
kubectl exec -t "$mysql_pod_name" -n back -- bash -c 'mysql -u root -pp@ssword < /tmp/init.sql'
kubectl exec -t "$mysql_pod_name" -n back -- rm /tmp/init.sql

# Añade una entrada en /etc/hosts si no existe
$ip = "127.0.0.1"
$hostsPath = "$env:windir\System32\drivers\etc\hosts"
$hostsContent = Get-Content $hostsPath
if ($hostsContent -contains "* php.internal") {
    Write-Host "Ya está el dominio php.internal en /etc/hosts"
} else {
    Add-Content -Path $hostsPath -Value "$ip `t php.internal"
    Write-Host "Se ha añadido el dominio php.internal a /etc/hosts"
}

# Crea un Ingress en Kubernetes y configura el port-forward
kubectl create ingress php-localhost --class=nginx --rule='php.internal/*=php-page:80' -n default
Start-Process powershell -ArgumentList "kubectl port-forward --namespace=ingress-nginx service/ingress-nginx-controller 8080:80"

Write-Host "FIN"
