# Laboratorio kubevuln con CVE-2021-43798

En este entorno de prueba se van a desplegar dos servicios, uno web PHP y otro para ver la monitorización y estadisticas de la web con Grafana. El objetivo principal es ver como podemos mitigar estas futuras vulnerabilidades similares o zero-day, para tener un sistema lo más bastionado posible.

## Arquitectura del laboratorio

![https://raw.githubusercontent.com/Alfesito/TFG-kubevuln/main/images/lab_architecture.png](https://raw.githubusercontent.com/Alfesito/TFG-kubevuln/main/images/lab_architecture.png)

El entorno de pruebas está pensado para que solo el servicio php-page esté expluesto la exterior del cluster.

## Despliegue del laboratorio

En este caso, utilizaremos Minikube y kubectl para levantar los servicios dentro del nodo de Minikube.

```bash
minikube start
kubectl apply -f grafana.yaml
kubectl apply -f php-page.yaml
```

Una vez estén todos los pods *Running*, prodeceremos a ejecutar el siguente comando para que Minikube nos lanze una dirección con el servio expuesto.

```bash
minikube service --all
```

## [CVE-2021-43798](https://www.exploit-db.com/exploits/50581)


La vulnerabilidad CVE-2021-43798 es una vulnerabilidad de directorio transversal (directory traversal) que afecta a Grafana, una plataforma de monitoreo y observabilidad de código abierto. La vulnerabilidad está presente en las versiones de Grafana 8.0.0-beta1 a 8.3.0, excepto las versiones parcheadas.

La vulnerabilidad se produce en la función ```getPluginFile()``` del módulo ```public/plugins``` de Grafana. Esta función se utiliza para cargar archivos de plugins de Grafana. La vulnerabilidad permite a un atacante inyectar caracteres especiales en la URL de una petición a la función ```getPluginFile()```. Estos caracteres especiales pueden utilizarse para acceder a archivos arbitrarios del sistema de archivos de Grafana, incluidos archivos confidenciales, como claves API, certificados SSL y archivos de configuración.

Para explotar la vulnerabilidad, un atacante puede enviar una petición HTTP a la URL ```(grafana_host_url)/public/plugins//```. En esta URL, ```grafana_host_url``` es la dirección URL del servidor Grafana. El atacante puede reemplazar el parámetro ```//``` con una ruta de directorio arbitraria. Por ejemplo, la siguiente petición HTTP permitiría al atacante leer el archivo ```/etc/passwd```:

```
GET /public/plugins//etc/passwd HTTP/1.1
Host: grafana.example.com
```

La vulnerabilidad se ha corregido en las versiones 8.4.0 y posteriores de Grafana. Los usuarios de Grafana que estén utilizando una versión vulnerable deben actualizar a la versión más reciente lo antes posible.

La vulnerabilidad CVE-2021-43798 fue descubierta por el investigador de seguridad Jas502n. La vulnerabilidad fue reportada a Grafana el 15 de junio de 2021 y fue corregida en la versión 8.4.0, publicada el 12 de julio de 2021.

El impacto de la vulnerabilidad es alto. Ya que al explotar la vulnerabilidad es posible obtener acceso a información confidencial almacenada en el sistema de archivos de Grafana. Esto podría utilizarse para realizar ataques de phishing, robo de identidad o sabotaje.