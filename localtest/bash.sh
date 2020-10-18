#!/bin/bash
yum install skopeo vim -y
cat >signsample <<EOF
      %echo Generating a basic OpenPGP key
      Key-Type: DSA
      Key-Length: 1024
      Subkey-Type: ELG-E
      Subkey-Length: 1024
      Name-Real: SignSample
      Name-Email: signsample@foo.bar
      Expire-Date: 0
      Passphrase: abc
      %pubring signsample.pub
      %secring signsample.sec
      # Do a commit here, so that we can later print "done" :-)
      %commit
      %echo done
EOF
gpg2 --batch --gen-key signsample
gpg2 --list-secret-keys
gpg2 --no-default-keyring --secret-keyring ./signsample.sec --keyring ./signsample.pub --list-secret-keys
APP_IMAGE="$(params.image-server)/$(params.image-namespace)/$(params.image-repository):$(params.image-tag)"
APP_RELEASE="$(params.image-release)"
NAME_IMAGE="$(params.image-repository):$(params.image-tag)"
buildah --layers --storage-driver=$(params.STORAGE_DRIVER) bud --format=$(params.FORMAT) --tls-verify=$(params.TLSVERIFY) -f $(params.DOCKERFILE) -t ${APP_IMAGE} $(params.CONTEXT)
set +x
if [[ -n "${REGISTRY_USER}" ]] && [[ -n "${REGISTRY_PASSWORD}" ]] && [[ "$(params.image-server)" != "image-registry.openshift-image-registry.svc:5000"  ]]; then
  buildah login -u "${REGISTRY_USER}" -p "${REGISTRY_PASSWORD}" "$(params.image-server)"
  echo "buildah login -u "${REGISTRY_USER}" -p "xxxxx" "$(params.image-server)""
fi
set -x
buildah --storage-driver=$(params.STORAGE_DRIVER) push --tls-verify=$(params.TLSVERIFY) --digestfile ./image-digest ${APP_IMAGE} docker://${APP_IMAGE}
skopeo inspect --tls-verify=false docker://${APP_IMAGE}
sed -i "s/var\/lib\/containers\/sigstore/tekton\/home\/.gnupg\//g" /etc/containers/registries.d/default.yaml
skopeo --tls-verify=false --insecure-policy --debug copy --sign-by signsample@foo.bar docker://${APP_IMAGE} docker://${APP_IMAGE}.signed