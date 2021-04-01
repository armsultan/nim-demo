FROM debian:buster-slim

LABEL maintainer="armand@f5.com"

RUN mkdir -p /etc/ssl/nginx
COPY etc/ssl/nginx/nginx-repo.crt /etc/ssl/nginx/nginx-repo.crt
COPY etc/ssl/nginx/nginx-repo.key /etc/ssl/nginx/nginx-repo.key

# Define versions for NGINX and NGINX modules
# http://nginx.org/en/download.html
ENV NGINX_VERSION   1.19.8
# https://nginx.org/en/docs/njs/changes.html
ENV NJS_VERSION   0.5.2     
ENV PKG_RELEASE     1~buster

# Set Instance Manager Server and Port and timeout for wait-for-it script
# (entrypoint.sh)
ARG COMPASS_PROTOCOL
ENV COMPASS_PROTOCOL=${COMPASS_PROTOCOL:-http}
ARG COMPASS_SYSTEMD
# Change to /lib/systemd/systemd for ubuntu
ENV COMPASS_SYSTEMD=${COMPASS_SYSTEMD:-/usr/sbin/init}
ARG COMPASS_SERVER
ENV COMPASS_SERVER=${COMPASS_SERVER:-nginx-manager.example.com}
ARG COMPASS_PORT
ENV COMPASS_PORT=${COMPASS_PORT:-11000}
ARG COMPASS_TIMEOUT
ENV COMPASS_TIMEOUT=${COMPASS_TIMEOUT:-15}

## Install NIM Agent
# Download certificate and key from the customer portal https://account.f5.com/myf5
# and copy to the build context and set correct permissions
# * nginx-repo.crt
# * nginx-repo.key

RUN mkdir -p /etc/ssl/nginx
COPY etc/ssl/nginx/nginx-repo.crt /etc/ssl/nginx/nginx-repo.crt
COPY etc/ssl/nginx/nginx-repo.key /etc/ssl/nginx/nginx-repo.key
COPY entrypoint.sh /

RUN set -x \
    # Set correct permissions on entrypoint and NGINX cert directory
    && chmod +x /entrypoint.sh \
    && chmod 644 /etc/ssl/nginx/* \
    # Remove Default NGINX Config
    && rm -rf  /etc/nginx/conf.d/* \
    # create nginx user/group first, to be consistent throughout docker variants
    && addgroup --system --gid 101 nginx \
    && adduser --system --disabled-login --ingroup nginx --no-create-home --home /nonexistent --gecos "nginx user" --shell /bin/false --uid 101 nginx \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y gnupg gnupg2 ca-certificates \
    && \
    NGINX_GPGKEY=573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62; \
    found=''; \
    for server in \
        ha.pool.sks-keyservers.net \
        hkp://keyserver.ubuntu.com:80 \
        hkp://p80.pool.sks-keyservers.net:80 \
        pgp.mit.edu \
    ; do \
        echo "Fetching GPG key $NGINX_GPGKEY from $server"; \
        apt-key adv --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$NGINX_GPGKEY" && found=yes && break; \
    done; \
    test -z "$found" && echo >&2 "error: failed to fetch GPG key $NGINX_GPGKEY" && exit 1; \
    apt-get remove --purge --auto-remove -y gnupg2 && rm -rf /var/lib/apt/lists/* \
    && dpkgArch="$(dpkg --print-architecture)" \
    && nginxPackages=" \
        nginx=${NGINX_VERSION}-${PKG_RELEASE} \
        nginx-module-xslt=${NGINX_VERSION}-${PKG_RELEASE} \
        nginx-module-geoip=${NGINX_VERSION}-${PKG_RELEASE} \
        nginx-module-image-filter=${NGINX_VERSION}-${PKG_RELEASE} \
        nginx-module-njs=${NGINX_VERSION}+${NJS_VERSION}-${PKG_RELEASE} \
    " \
    && case "$dpkgArch" in \
        amd64|i386|arm64) \
# arches officialy built by upstream
            echo "deb https://nginx.org/packages/mainline/debian/ buster nginx" >> /etc/apt/sources.list.d/nginx.list \
            && apt-get update \
            ;; \
        *) \
# we're on an architecture upstream doesn't officially build for
# let's build binaries from the published source packages
            echo "deb-src https://nginx.org/packages/mainline/debian/ buster nginx" >> /etc/apt/sources.list.d/nginx.list \
            \
# new directory for storing sources and .deb files
            && tempDir="$(mktemp -d)" \
            && chmod 777 "$tempDir" \
# (777 to ensure APT's "_apt" user can access it too)
            \
# save list of currently-installed packages so build dependencies can be cleanly removed later
            && savedAptMark="$(apt-mark showmanual)" \
            \
# build .deb files from upstream's source packages (which are verified by apt-get)
            && apt-get update \
            && apt-get build-dep -y $nginxPackages \
            && ( \
                cd "$tempDir" \
                && DEB_BUILD_OPTIONS="nocheck parallel=$(nproc)" \
                    apt-get source --compile $nginxPackages \
            ) \
# we don't remove APT lists here because they get re-downloaded and removed later
            \
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
# (which is done after we install the built packages so we don't have to redownload any overlapping dependencies)
            && apt-mark showmanual | xargs apt-mark auto > /dev/null \
            && { [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; } \
            \
# create a temporary local APT repo to install from (so that dependency resolution can be handled by APT, as it should be)
            && ls -lAFh "$tempDir" \
            && ( cd "$tempDir" && dpkg-scanpackages . > Packages ) \
            && grep '^Package: ' "$tempDir/Packages" \
            && echo "deb [ trusted=yes ] file://$tempDir ./" > /etc/apt/sources.list.d/temp.list \
# work around the following APT issue by using "Acquire::GzipIndexes=false" (overriding "/etc/apt/apt.conf.d/docker-gzip-indexes")
#   Could not open file /var/lib/apt/lists/partial/_tmp_tmp.ODWljpQfkE_._Packages - open (13: Permission denied)
#   ...
#   E: Failed to fetch store:/var/lib/apt/lists/partial/_tmp_tmp.ODWljpQfkE_._Packages  Could not open file /var/lib/apt/lists/partial/_tmp_tmp.ODWljpQfkE_._Packages - open (13: Permission denied)
            && apt-get -o Acquire::GzipIndexes=false update \
            ;; \
    esac \
    \
    # EDIT: Extra steps to install nginx-agent for NIM 
    # Install the required prerequsites and certificate authority dependencies
    && apt-get install --no-install-recommends --no-install-suggests -y wget apt-transport-https lsb-release  \
    # && wget https://nginx.org/keys/nginx_signing.key \
    # && apt-key add nginx_signing.key \
    # Install the NGINX repository file
    && printf "deb https://pkgs.nginx.com/instance-manager/debian stable nginx-plus\n" | tee /etc/apt/sources.list.d/instance-manager.list \
    && wget -q -O /etc/apt/apt.conf.d/90pkgs-nginx https://cs.nginx.com/static/files/90pkgs-nginx \
    && apt-get update -y \
    && apt-get install --no-install-recommends --no-install-suggests -y \
                        $nginxPackages \
                        gettext-base \
                        curl \
                        # EDIT: And install nginx-agent 
                        nginx-agent \
    && apt-get remove --purge --auto-remove -y && rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/nginx.list \
# if we have leftovers from building, let's purge them (including extra, unnecessary build deps)
    && if [ -n "$tempDir" ]; then \
        apt-get purge -y --auto-remove \
        && rm -rf "$tempDir" /etc/apt/sources.list.d/temp.list; \
    fi \
    # Other Edits
    # Optional: Create cache folder and set permissions for proxy caching
    && mkdir -p /var/cache/nginx \
    && chown -R nginx /var/cache/nginx \
    # Make sure Nginx-agent conf folder exists
    && mkdir -p /etc/nginx-agent \
    && chown -R nginx /etc/nginx-agent \
    # Set permissions
    && chown -R nginx:nginx /etc/nginx \
    # forward request and error logs to docker log collector
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    # Raise the limits to successfully run benchmarks
    && ulimit -c -m -s -t unlimited \
    # Cleanup
    && apt-get remove --purge --auto-remove -y gnupg2 lsb-release \  
    && rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/nginx-plus.list \
    && rm /etc/apt/sources.list.d/instance-manager.list \
    && rm -rf nginx_signing.key

## Configs
# Enable Custom default page, pick one
# 1. Plaintext
# ADD etc/nginx/conf.d/hello-plain-text.conf /etc/nginx/conf.d/
# 2. HTML Page - start #
ADD etc/nginx/conf.d/hello-html.conf /etc/nginx/conf.d/
COPY usr/share/nginx/html/ /usr/share/nginx/html/
# HTML Page - end #
# Copy nginx-agent config file
ADD etc/nginx-agent/nginx-agent.conf /etc/nginx-agent/nginx-agent.conf

# EXPOSE ports HTTP 80 and HTTPS 443
EXPOSE 80 443
STOPSIGNAL SIGTERM
ENTRYPOINT ["/entrypoint.sh"]