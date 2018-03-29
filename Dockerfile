# Version: 0.0.1
FROM jenkins/jenkins:lts-alpine
LABEL org.thenuclei.creator="Brian Provenzano" \
      org.thenuclei.email="brian@thenuclei.org"
USER root
RUN apk add --no-cache python3 bash git && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install requests
ADD hashicorp-get /bin/hashicorp-get
RUN chmod +x /bin/hashicorp-get
RUN hashicorp-get terraform latest -y -q && hashicorp-get packer latest -y -q
COPY --chown=jenkins:jenkins basic-security.groovy /var/jenkins_home/init.groovy.d/basic-security.groovy
#COPY --chown=jenkins:jenkins jenkins.install.UpgradeWizard.state /var/jenkins_home/
RUN echo 2 > /var/jenkins_home/jenkins.install.UpgradeWizard.state
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt
USER jenkins