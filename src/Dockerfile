FROM nginx:1.19.6 as build

# https://gist.github.com/muuvmuuv/f1a0e7b6a6a02c2253dc92350eab7607
ENV build_deps "build-essential wget git apt-transport-https ca-certificates"
RUN apt-get update && apt-get install -y --no-install-recommends $build_deps
RUN mkdir /root/temp

RUN cd /root/temp \
 && wget https://hg.nginx.org/pkg-oss/raw-file/tip/build_module.sh \
  # remove sudo from file because we are sudo
  && sed -i -e '152,158d' -e 's/sudo //' ./build_module.sh

RUN cd /root/temp \
  && git clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git \
  && cd ngx_http_substitutions_filter_module \
  && git submodule update --init --recursive

RUN cd /root/temp \
  && sh ./build_module.sh -y -f -v $NGINX_VERSION ./ngx_http_substitutions_filter_module \
  && pkg=$(find /root/temp/build-module-artifacts -type f -name "nginx-module-substitutionsfilter*.deb" -print) \
  && dpkg -i ${pkg}


FROM nginx:1.19.6

COPY --from=build /usr/lib/nginx/modules/* /usr/lib/nginx/modules/

WORKDIR /app
COPY nginx.conf .
COPY start.sh .

EXPOSE 80
CMD ["./start.sh"]
