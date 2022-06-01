FROM debian:stable AS builder

ARG version=1.19.6
ARG modules_dir="/usr/lib/nginx/modules/"
ARG build_dir="/usr/share/tmp"

# Setup
RUN apt-get update
RUN apt-get install -y --no-install-recommends \
  ca-certificates \
  wget \
  git \
  build-essential \
  libpcre3-dev \
  zlib1g-dev \
  libzstd-dev
RUN mkdir -p ${build_dir}
RUN mkdir -p ${modules_dir}

# Download NGINX
RUN cd ${build_dir} \
  && wget https://nginx.org/download/nginx-${version}.tar.gz \
  && tar zxf nginx-${version}.tar.gz \
  && rm nginx-${version}.tar.gz

# # Download Modules
RUN cd ${build_dir} \
#   && git clone --recursive https://github.com/google/ngx_brotli.git brotli \
  && git clone --recursive https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git subs

# Install modules
RUN cd ${build_dir}/nginx-${version} \
  && ./configure \
  --with-compat \
  # --with-http_sub_module \
  # --add-dynamic-module=../brotli  \
  --add-dynamic-module=../subs  \
  && make \
  && make install

# Move compiled modules
RUN cd ${build_dir}/nginx-${version}/objs \
  && cp *.so ${modules_dir} \
  && chmod -R 644 ${modules_dir}

FROM nginx:1.19.6

COPY --from=builder /usr/lib/nginx/modules/* /usr/lib/nginx/modules/
RUN ls /usr/lib/nginx/modules/

WORKDIR /app
COPY nginx.conf .
COPY start.sh .

EXPOSE 80
CMD ["./start.sh"]
