FROM centos
#RUN yum install jq -y
WORKDIR /usr/skopeo/
COPY ./dev/signsample .
#RUN gpg --batch -v -r --gen-key signsample
#RUN gpg --list-secret-keys
#RUN gpg --list-keys