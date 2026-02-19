FROM openresty/openresty:1.27.1.2-0-alpine

RUN apk add --no-cache perl curl

RUN /usr/local/openresty/bin/opm get zmartzone/lua-resty-openidc \
    && /usr/local/openresty/bin/opm get bungle/lua-resty-session \
    && /usr/local/openresty/bin/opm get ledgetech/lua-resty-http

COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY lua/ /etc/nginx/lua/
