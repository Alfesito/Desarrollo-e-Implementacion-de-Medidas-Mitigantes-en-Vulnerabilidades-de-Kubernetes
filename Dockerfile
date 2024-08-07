FROM ubuntu:20.04

# Actualizar paquetes e instalar dependencias
RUN apt-get update && apt-get install -y \
    curl \
    apt-transport-https \
    ca-certificates \
    software-properties-common \
    conntrack

# Instalar Docker
RUN apt-get update && \
    apt-get install -y docker.io

# Instalar Minikube
RUN curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && \
    chmod +x minikube && \
    mv minikube /usr/local/bin/

# Instalar kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

# Configurar el punto de entrada
ENTRYPOINT ["minikube", "start", "--driver=docker"]
