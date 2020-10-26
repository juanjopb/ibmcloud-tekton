#!/bin/bash
#yum install skopeo vim -y
yum install pinentry -y
cat >signsample <<EOF
      #%echo Generating a basic OpenPGP key
      %no-protection
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
PASSPHRASE=abc
export GPG_TTY=$(tty)
echo "*****Create gpg-agent.conf"
ls /usr/bin/pinentry-curses
echo ‘pinentry-program /usr/bin/pinentry-curses’ > ~/.gnupg/gpg-agent.conf
cat >/etc/gnupg/gpg-agent.conf <<EOF
      pinentry-program /usr/bin/pinentry-curses
      allow-loopback-pinentry
EOF
echo "*****Create gpg.conf"
cat >~/.gnupg/gpg.conf <<EOF
      use-agent 
      pinentry-mode loopback
EOF
echo "********* Located on ******"
pwd
gpg --batch -v --gen-key signsample
echo "*********Firts List Keys"
gpg --list-keys
echo "*********Import the Public GPG to Keystore"

gpg --import signsample.pub
echo "*********List Secret Keys"
gpg --list-secret-keys
echo "*********List Keys"
gpg --list-keys
echo "*********Make sigstore"
mkdir -p /source/sigstore/
chmod 777 /source/sigstore/
echo "*********Make sigstore "
echo "*********Change Path Sigstore"
sed -i "s/var\/lib\/containers\/sigstore/source\/sigstore\//g" /etc/containers/registries.d/default.yaml
echo "*********Make sigstore"
cat /etc/containers/registries.d/default.yaml
ls -lsrt ~/.gnupg/
echo "*********Export public key"
gpg --armor --export signsample@foo.bar > sign-sample.pub
SIGN_CA=$(cat sign-sample.pub)
echo "*********PRINT public key"
echo "${SIGN_CA}"
cat ~/.gnupg/gpg.conf

echo "*****REstart Agent"
#echo RELOADAGENT | gpg-connect-agent
echo "*****SKOPEO DOCKER with Sign and passhprase"
echo "********************************************"
echo "********************************************"
#--registries.d=/source/sigstore/
skopeo copy --debug --dest-creds=juanjosepb:Pillin52 --insecure-policy --src-tls-verify=false --dest-tls-verify=false --sign-by signsample@foo.bar docker://juanjosepb/nginx:1.0 docker://docker.io/juanjosepb/signedimage:3.0.signed <<<$PASSPHRASE
