#!/bin/bash
#ATENCION! Este script solo está probado para microk8s

ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

cd encription-provider
cat > encryption_provider.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF
dir_actual=$(pwd)
dir_api=$(pgrep -an kubelite | grep -oP -- '--apiserver-args-file=\K[^ ]+')
echo "--encryption-provider-config=$dir_actual/encryption_provider.yaml" >> "$dir_api"
cd ..
# Se reinicia kubelite para cargar la nueva configuración
sudo systemctl restart snap.microk8s.daemon-kubelite
status= $(systemctl is-active snap.microk8s.daemon-kubelite)
sleep 10
microk8s kubectl get secrets --all-namespaces -o json | microk8s kubectl replace -f --all-namespaces -