# Usa la imagen base de Ubuntu
FROM ubuntu:20.04

# Establece el entorno no interactivo para evitar las preguntas durante la instalación
ENV DEBIAN_FRONTEND=noninteractive

# Actualiza los paquetes y instala dependencias necesarias
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    sudo \
    software-properties-common \
    virtualbox \
    virtualbox-ext-pack \
    && apt-get clean

# Instala kubectl
RUN apt-get update && apt-get install -y kubectl

# Instala Minikube
RUN curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && \
    chmod +x minikube && \
    mv minikube /usr/local/bin/

# Clona el repositorio específico
RUN git clone https://github.com/Alfesito/Desarrollo-e-Implementacion-de-Medidas-Mitigantes-en-Vulnerabilidades-de-Kubernetes.git /root/project

# Define el punto de entrada para el contenedor
ENTRYPOINT ["/root/Desarrollo-e-Implementacion-de-Medidas-Mitigantes-en-Vulnerabilidades-de-Kubernetes/kube-lab/start_minikube_lab.sh"]
