FROM debian:jessie
LABEL version="1.11.2.2"

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    apt-utils \
    ca-certificates \
    curl \
    build-essential \
    git \
    libgeoip-dev \
    libpcre3-dev \
    libreadline-dev \
    libssl-dev \
    make \
    perl \
    unzip \
    zlib1g-dev \
  && rm -rf /var/lib/apt/lists/*

ENV OPENRESTY_VERSION 1.11.2.2
ENV OPENRESTY_PREFIX /opt/openresty
ENV NGINX_PREFIX /opt/openresty/nginx
ENV VAR_PREFIX /var/nginx
ENV LUAROCKS_VERSION 2.3.0

RUN curl -sSL http://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz | tar -xvz \
  && cd openresty-* \
  && readonly NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
  && ./configure \
    --prefix=$OPENRESTY_PREFIX \
    --http-client-body-temp-path=$VAR_PREFIX/client_body_temp \
    --http-proxy-temp-path=$VAR_PREFIX/proxy_temp \
    --http-log-path=$VAR_PREFIX/access.log \
    --error-log-path=$VAR_PREFIX/error.log \
    --pid-path=$VAR_PREFIX/nginx.pid \
    --lock-path=$VAR_PREFIX/nginx.lock \
    --with-http_auth_request_module \
    --with-http_geoip_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-ipv6 \
    --with-luajit \
    --with-pcre-jit \
    --without-http_fastcgi_module \
    --without-http_uwsgi_module \
    --without-http_userid_module \
    --without-http_scgi_module \
    --without-http_ssi_module \
    -j${NPROC} \
  && make -j${NPROC} \
  && make install \
  && ln -sf $NGINX_PREFIX/sbin/nginx /usr/local/bin/nginx \
  && ln -sf $NGINX_PREFIX/sbin/nginx /usr/local/bin/openresty \
  && ln -sf $OPENRESTY_PREFIX/bin/resty /usr/local/bin/resty \
  && ln -sf $OPENRESTY_PREFIX/luajit/bin/luajit-* $OPENRESTY_PREFIX/luajit/bin/lua \
  && ln -sf $OPENRESTY_PREFIX/luajit/bin/luajit-* /usr/local/bin/lua \
  && rm -rf /root/openresty*

RUN curl -sSL http://keplerproject.github.io/luarocks/releases/luarocks-${LUAROCKS_VERSION}.tar.gz | tar -xvz -C /root/ \
  && cd /root/luarocks-* \
  && ./configure \
    --with-lua=$OPENRESTY_PREFIX/luajit/ \
    --with-lua-include=$OPENRESTY_PREFIX/luajit/include/luajit-2.1 \
    --with-lua-lib=$OPENRESTY_PREFIX/lualib \
  && make build \
  && make install \
  && rm -rf /root/luarocks*

WORKDIR $NGINX_PREFIX/

CMD ["nginx", "-g", "daemon off; error_log /dev/stderr info;"]
