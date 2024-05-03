#!/bin/bash
#ATENCION! Este script solo está probado para microk8s

ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
echo $ENCRYPTION_KEY

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
#pgrep -an kubelite | grep -oP -- '--apiserver-args-file=\K[^ ]+'
echo "--encryption-provider-config=$dir_actual/encryption_provider.yaml" >> /var/snap/microk8s/6641/args/kube-apiserver
cd ..
# Se reinicia kubelite para cargar la nueva configuración
sudo systemctl restart snap.microk8s.daemon-kubelite
status= $(systemctl is-active snap.microk8s.daemon-kubelite)
sleep 10
#kubectl get secrets --all-namespaces -o json | kubectl replace -f --all-namespaces -