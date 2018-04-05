# Version: 0.0.1
FROM jenkins/jenkins:lts-alpine
LABEL org.thenuclei.creator="Brian Provenzano" \
      org.thenuclei.email="brian@thenuclei.org"
USER root

RUN apk add --no-cache python3 alpine-conf tzdata bash git \
    ca-certificates \
    \
    # .NET Core dependencies
    # taken from  https://github.com/dotnet/dotnet-docker/tree/nightly/2.1/runtime-deps/alpine/amd64
    #  dotnet-docker/2.1/runtime-deps/alpine/amd64/Dockerfile
    krb5-libs \
    libgcc \
    libintl \
    libssl1.0 \
    libstdc++ \
    #tzdata \
    userspace-rcu \
    zlib \
    && apk -X https://dl-cdn.alpinelinux.org/alpine/edge/main add --no-cache \
        lttng-ust && \
    # Being Python builds needs
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install requests flask pytest pytest-runner

# Configure Kestrel web server to bind to port 80 when present
#ENV ASPNETCORE_URLS=http://+:80 \
# Enable detection of running in a container
ENV DOTNET_RUNNING_IN_CONTAINER=true \
# Set the invariant mode since icu_libs isn't included (see https://github.com/dotnet/announcements/issues/20)
DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=true

#Taken from https://github.com/dotnet/dotnet-docker/tree/nightly/2.1/sdk/alpine/amd64
# dotnet-docker/2.1/sdk/alpine/amd64/Dockerfile
# Disable the invariant mode (set in base image)
RUN apk add --no-cache icu-libs

ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8

# Install .NET Core SDK
ENV DOTNET_SDK_VERSION 2.1.300-preview2-008523

RUN apk add --no-cache --virtual .build-deps \
        openssl \
    && wget -O dotnet.tar.gz https://dotnetcli.blob.core.windows.net/dotnet/Sdk/$DOTNET_SDK_VERSION/dotnet-sdk-$DOTNET_SDK_VERSION-alpine.3.6-x64.tar.gz \
    && dotnet_sha512='c42843332eeb5a0a758011ac38d32e7575af6731264312030a134107539bf10621d97245a90aae91b7120d6c871c7151f16bf1866468eeb68e6768c1f6a63f58' \
    && echo "$dotnet_sha512  dotnet.tar.gz" | sha512sum -c - \
    && mkdir -p /usr/share/dotnet \
    && tar -C /usr/share/dotnet -xzf dotnet.tar.gz \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet \
    && rm dotnet.tar.gz \
    && apk del .build-deps

# Enable correct mode for dotnet watch (only mode supported in a container)
ENV DOTNET_USE_POLLING_FILE_WATCHER=true \ 
    # Skip extraction of XML docs - generally not useful within an image/container - helps perfomance
    NUGET_XMLDOC_MODE=skip

# Trigger first run experience by running arbitrary cmd to populate local package cache
RUN dotnet help
# Finish setup
RUN setup-timezone -z America/Los_Angeles && ntpd -d -q -n -p north-america.pool.ntp.org
ADD hashicorp-get /bin/hashicorp-get
RUN chmod +x /bin/hashicorp-get
RUN hashicorp-get terraform latest -y -q && hashicorp-get packer latest -y -q
COPY --chown=jenkins:jenkins basic-security.groovy /var/jenkins_home/init.groovy.d/basic-security.groovy
#COPY --chown=jenkins:jenkins jenkins.install.UpgradeWizard.state /var/jenkins_home/
RUN echo 2 > /var/jenkins_home/jenkins.install.UpgradeWizard.state
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt
USER jenkins