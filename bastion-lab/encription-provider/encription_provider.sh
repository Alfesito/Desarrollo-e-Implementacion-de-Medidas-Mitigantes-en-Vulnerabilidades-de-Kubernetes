#!/bin/bash
#ATENCION! Este script solo está probado para microk8s

ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
echo $ENCRYPTION_KEY

dir_actual=$(pwd)
cd encription-provider
cat > encryption-provider.yaml <<EOF
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

#file_name=$(pgrep -an kubelite | grep -oP -- '--apiserver-args-file=\K[^ ]+')
file_name=/var/snap/microk8s/current/args/kubelite
echo "--encryption-provider-config=$dir_actual/encryption_provider.yaml" >> "$file_name"
cd ..
# Se reinicia kubelite para cargar la nueva configuración
sudo systemctl restart snap.microk8s.daemon-kubelite
while [[ $(systemctl is-active snap.microk8s.daemon-kubelite) != "active" ]]; do
    sleep 1
done

kubectl get secrets --all-namespaces -o json | kubectl replace -f --all-namespaces -