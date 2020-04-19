# syntax=docker/dockerfile:experimental
# https://github.com/grantmacken/alpine-nginx
# https://github.com/agile6v/awesome-nginx
# dynamic modules
# installed
# https://github.com/openresty/echo-nginx-module/releases
# TODO
# https://github.com/calio/form-input-nginx-module/releases
# https://github.com/openresty/set-misc-nginx-module/releases
# https://github.com/calio/form-input-nginx-module/releases
# https://github.com/openresty/array-var-nginx-module
# https://github.com/openresty/headers-more-nginx-module/releases
# https://github.com/vision5/ngx_devel_kit/releases
# for caching with redis
# https://www.nginx.com/resources/wiki/modules/redis/
# https://github.com/openresty/redis2-nginx-module/releases
# https://github.com/openresty/srcache-nginx-module

# https://github.com/openresty/replace-filter-nginx-module
# https://github.com/openresty/stream-echo-nginx-module


FROM alpine:3.11 as bld
# LABEL maintainer="${GIT_USER_NAME} <${GIT_USER_EMAIL}>"
# https://github.com/ricardbejarano/nginx/blob/master/Dockerfile.musl
# https://github.com/nginx-modules/nginx-docker-container


ARG PREFIX
ARG MODULES="${PREFIX}/modules"
ARG NGINX_VER
ARG PCRE_VER
ARG ZLIB_VER
ARG OPENSSL_VER

ARG ECHO_VER
ARG HEADERS_MORE_VER
ARG NGX_DEVEL_KIT
ARG SET_MISC_VER
ARG FORM_INPUT_VER

ARG PCRE_PREFIX="${PREFIX}/pcre"
ARG PCRE_LIB="${PCRE_PREFIX}/lib"
ARG PCRE_INC="${PCRE_PREFIX}/include"
ARG ZLIB_PREFIX="${PREFIX}/zlib"
ARG ZLIB_LIB="${ZLIB_PREFIX}/lib"
ARG ZLIB_INC="${ZLIB_PREFIX}/include"
ARG OPENSSL_PREFIX="${PREFIX}/openssl"
ARG OPENSSL_LIB="${OPENSSL_PREFIX}/lib"
ARG OPENSSL_INC="${OPENSSL_PREFIX}/include"
# https://github.com/nginx-modules

RUN --mount=type=cache,target=/var/cache/apk \
    ln -vs /var/cache/apk /etc/apk/cache \
    && apk add --virtual .build-deps \
       build-base \
       gd-dev \
       linux-headers \
       openssl-dev \
       pcre-dev \
       perl-dev \
       zlib-dev

WORKDIR /home
ADD https://zlib.net/zlib-${ZLIB_VER}.tar.gz ${WORKDIR}/zlib.tar.gz
RUN echo ' - install zlib' \
    && echo '   ------------' \
    && echo "${WORKDIR}"\
    &&  tar -C /tmp -xf ${WORKDIR}/zlib.tar.gz \
    && cd /tmp/zlib-${ZLIB_VER} \
    && ./configure --prefix=${ZLIB_PREFIX} \
    && make && make install \
    && cd ${WORKDIR} \
    && rm ${WORKDIR}/zlib.tar.gz \
    && rm -r ${ZLIB_PREFIX}/share \
    && rm -r /tmp/zlib-${ZLIB_VER} \
    && echo '---------------------------'

# # https://github.com/openresty/openresty-packaging/blob/master/deb/openresty-openssl/debian/rules
ADD https://www.openssl.org/source/openssl-${OPENSSL_VER}.tar.gz ${WORKDIR}/openssl.tar.gz
RUN echo ' - install openssl' \
   && echo '   ------------' \
   && tar -C /tmp -xf ${WORKDIR}/openssl.tar.gz \
   && cd /tmp/openssl-${OPENSSL_VER} \
   && ./config \
   no-tests \
   no-threads shared zlib -g \
   enable-ssl3 enable-ssl3-method \
    --prefix=${OPENSSL_PREFIX} \
    --libdir=lib \
    -I${ZLIB_INC} \
    -L${ZLIB_LIB} \
    -Wl,-rpath,${ZLIB_LIB}:${OPENSSL_LIB} \
    && make && make install_sw \
    && cd ${WORKDIR} \
    && rm ${WORKDIR}/openssl.tar.gz \
    && rm  ${OPENSSL_PREFIX}/bin/c_rehash \
    && rm -rf ${OPENSSL_PREFIX}/lib/pkgconfig \
    && rm -r /tmp/openssl-${OPENSSL_VER} \
    && echo '---------------------------'

ADD https://ftp.pcre.org/pub/pcre/pcre-${PCRE_VER}.tar.gz ${WORKDIR}/pcre.tar.gz
RUN echo ' - install pcre' \
    &&  tar -C /tmp -xf ${WORKDIR}/pcre.tar.gz \
    && cd /tmp/pcre-${PCRE_VER} \
    && ./configure \
    --disable-cpp \
    --prefix=${PCRE_PREFIX} \
    --enable-jit \
    --enable-utf \
    --enable-unicode-properties \
    && make && make install \
    && cd ${WORKDIR} \
    && rm -f ${WORKDIR}/pcre.tar.gz \
    && rm -rf ${PCRE_PREFIX}/bin \
    && rm -rf ${PCRE_PREFIX}/share \
    && rm -f ${PCRE_PREFIX}/lib/*.la \
    && rm -f ${PCRE_PREFIX}/lib/*pcreposix* \
    && rm -rf ${PCRE_PREFIX}/lib/pkgconfig \
    && rm -r /tmp/pcre-${PCRE_VER} \
    && echo '---------------------------'

# ARG ECHO_VER
# ARG HEADERS_MORE_VER
# ARG NGX_DEVEL_KIT
# ARG SET_MISC_VER

ADD https://github.com/openresty/echo-nginx-module/archive/${ECHO_VER}.tar.gz ${WORKDIR}/echo-nginx-module.tar.gz
RUN echo ' - unpack echo-nginx-module ' \
    && mkdir /home/modules \
    && tar -C /home/modules -xf ${WORKDIR}/echo-nginx-module.tar.gz \
    && cd modules && mv echo-nginx-module*  echo-nginx-module

ADD https://github.com/vision5/ngx_devel_kit/archive/${NGX_DEVEL_KIT}.tar.gz ${WORKDIR}/ngx_devel_kit.tar.gz
RUN echo ' - unpack ngx_devel_kit' \
    && tar -C /home/modules -xf ${WORKDIR}/ngx_devel_kit.tar.gz \
    && cd modules && mv ngx_devel_kit*  ngx_devel_kit

ADD https://github.com/openresty/set-misc-nginx-module/archive/${SET_MISC_VER}.tar.gz ${WORKDIR}/set-misc-nginx-module.tar.gz
RUN echo ' - unpack set-misc-nginx-module' \
    && tar -C /home/modules -xf ${WORKDIR}/set-misc-nginx-module.tar.gz \
    && cd modules && mv set-misc-nginx-module*  set-misc-nginx-module

ADD https://github.com/openresty/headers-more-nginx-module/archive/${HEADERS_MORE_VER}.tar.gz ${WORKDIR}/headers-more-nginx-module.tar.gz
RUN echo ' - unpack headers-more-nginx-module' \
    && tar -C /home/modules -xf ${WORKDIR}/headers-more-nginx-module.tar.gz \
    && cd modules && mv headers-more-nginx-module*  headers-more-nginx-module

ADD https://github.com/calio/form-input-nginx-module/archive/${FORM_INPUT_VER}.tar.gz ${WORKDIR}/form-input-nginx-module.tar.gz
RUN echo ' - unpack form-input-nginx-module' \
    && tar -C /home/modules -xf ${WORKDIR}/form-input-nginx-module.tar.gz \
    && cd modules && mv form-input-nginx-module* form-input-nginx-module

#     --with-cc-opt="-I${OPENSSL_INC} -I${PCRE_INC} -I${ZLIB_INC} " \
#     --with-ld-opt="-L${PCRE_LIB} -L${OPENSSL_LIB} -L${ZLIB_LIB} -Wl,-rpath,${PCRE_LIB}:${OPENSSL_LIB}:${ZLIB_LIB}" \
# https://github.com/openresty/openresty-packaging/blob/master/deb/openresty/debian/rules
WORKDIR /home
ADD  https://nginx.org/download/nginx-${NGINX_VER}.tar.gz ${WORKDIR}/nginx.tar.gz
RUN echo    ' - install nginx' \
    && echo '   -----------------' \
    &&  tar -C /tmp -xvf ${WORKDIR}/nginx.tar.gz \
    && cd /tmp/nginx-${NGINX_VER} \
    && ./configure \
    --with-cc-opt="-I${PCRE_INC} -I${ZLIB_INC} -I${OPENSSL_INC} " \
    --with-ld-opt="-L${PCRE_LIB} -L${ZLIB_LIB} -L${OPENSSL_LIB} -Wl,-rpath,${PCRE_LIB}:${ZLIB_LIB}:${OPENSSL_LIB}" \
    \
    --prefix=${PREFIX} \
    --modules-path=/${MODULES} \
    \
    --without-http_scgi_module \
    --without-http_ssi_module \
    --without-http_uwsgi_module \
    --without-http_uwsgi_module \
    --without-http_split_clients_module \
    --without-http_memcached_module \
    --without-http_empty_gif_module \
    --without-http_auth_basic_module \
    --without-http_autoindex_module \
    --without-http_geo_module \
    \
    --with-http_auth_request_module \
    --with-file-aio \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-ipv6 \
    --with-pcre-jit \
    --with-stream \
    --with-stream_ssl_module \
    --with-threads \
    \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_slice_module \
    --with-http_stub_status_module \
    --add-dynamic-module=/home/modules/echo-nginx-module \
    --add-dynamic-module=/home/modules/ngx_devel_kit \
    --add-dynamic-module=/home/modules/set-misc-nginx-module \
    --add-dynamic-module=/home/modules/headers-more-nginx-module \
    --add-dynamic-module=/home/modules/form-input-nginx-module \
    && make && make install \
    && rm ${WORKDIR}/nginx.tar.gz \
    && rm -r /tmp/nginx-${NGINX_VER} \
    && mv ${PREFIX}/conf/mime.types ${WORKDIR}/ \
    && rm ${PREFIX}/conf/* \
    && mv ${WORKDIR}/mime.types ${PREFIX}/conf/ \
    && mkdir ${PREFIX}/cache \
    && mkdir -p ${PREFIX}/html/.well-known/acme-challange \
    && echo ' - remove apk install deps' \
    && apk del .build-deps \
    && echo '---------------------------'

 # --add-dynamic-module /home/modules/echo-nginx-module \

FROM alpine:3.11
WORKDIR /usr/local/nginx
ENV NGINX_HOME /usr/local/nginx
ENV LANG C.UTF-8

COPY --from=bld /usr/local/nginx /usr/local/nginx
COPY ./proxy/conf/nginx.conf /usr/local/nginx/conf/
RUN apk add --no-cache tzdata \
    && mkdir -p /etc/letsencrypt \
    && ln -sf /dev/stdout logs/access.log \
    && ln -sf /dev/stderr logs/error.log \
    && ./sbin/nginx -t

EXPOSE 80 443
STOPSIGNAL SIGTERM
ENTRYPOINT ["sbin/nginx", "-g", "daemon off;"]
