# Version: 0.0.1
FROM jenkins/jenkins:lts-alpine
LABEL org.thenuclei.creator="Brian Provenzano" \
      org.thenuclei.email="bproven@example.com"
USER root
RUN apk add --no-cache python3 bash git && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install requests
ADD hashicorp-get /bin/hashicorp-get
RUN chmod +x /bin/hashicorp-get
RUN hashicorp-get terraform latest -y -q && hashicorp-get packer latest -y -q
USER jenkins