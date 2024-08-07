# Especificar la plataforma ARM
FROM --platform=linux/arm64 ubuntu:20.04

# Configurar el entorno para evitar preguntas interactivas durante la instalación
ENV DEBIAN_FRONTEND=noninteractive

# Actualizar paquetes e instalar dependencias
RUN apt-get update && apt-get install -y \
    curl \
    apt-transport-https \
    ca-certificates \
    software-properties-common \
    conntrack \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Instalar Docker
RUN apt-get update && \
    apt-get install -y docker.io \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Instalar Minikube para ARM
RUN curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-arm64 && \
    chmod +x minikube && \
    mv minikube /usr/local/bin/

# Instalar kubectl para ARM
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

# Clonar el repositorio de GitHub
RUN git clone https://github.com/Alfesito/Desarrollo-e-Implementacion-de-Medidas-Mitigantes-en-Vulnerabilidades-de-Kubernetes.git /root/kube-lab

# Exponer el puerto 8080
EXPOSE 8080

# Configurar el punto de entrada con lógica de reintento
ENTRYPOINT sh -c "minikube start --driver=docker --force && (/root/kube-lab/start_minikube_lab.sh || /root/kube-lab/start_minikube_lab.sh)"