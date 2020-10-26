FROM quay.io/buildah/stable:v1.15.0

RUN yum install skopeo vim  -y
COPY localtest/bash.sh .
RUN chmod +x bash.sh