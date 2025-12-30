# Base image
FROM nginx:1.25.3
USER 0
# Install build tools, dependencies, procps, bash, and FFmpeg
RUN apt-get update && \
    apt-get install -y \
        git gcc make \
        libpcre3 libpcre3-dev \
        zlib1g zlib1g-dev \
        libssl-dev wget \
        openssh-client \
        procps bash ffmpeg net-tools && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y python3-full python3-pip python3-venv

# Build Nginx with RTMP and MP4 modules
RUN cd /tmp && \
    wget http://nginx.org/download/nginx-1.25.3.tar.gz && \
    tar -zxvf nginx-1.25.3.tar.gz && \
    git clone https://github.com/arut/nginx-rtmp-module.git && \
    cd nginx-1.25.3 && \
    ./configure \
        --with-http_ssl_module \
        --with-http_mp4_module \
        --add-module=../nginx-rtmp-module && \
    make && make install && \
    rm -rf /tmp/*

# Prepare runtime directories for the custom Nginx
RUN mkdir -p /var/www/html/nginx_client_body_temp \
         /var/www/html/nginx_proxy_temp \
         /var/www/html/nginx_fastcgi_temp
RUN chmod -R 777 /var/www/html/nginx_*_temp

RUN mkdir -p /usr/local/nginx/{conf,logs} \
    /usr/local/nginx/{client_body_temp,proxy_temp,fastcgi_temp,uwsgi_temp,scgi_temp} && \
    chmod -R 777 /usr/local/nginx

# Create web root
RUN mkdir -p /var/www/html/show && chmod -R 777 /var/www/html

# Copy configs into the *custom Nginx* path
COPY nginx.conf /usr/local/nginx/conf/nginx.conf
COPY conf.d/ /usr/local/nginx/conf/conf.d/

# Expose HTTP and RTMP ports
EXPOSE 80 8080 1935 443
# Install livestream

# Copy SSH private key and configure access
COPY id_rsa /root/.ssh/id_rsa
RUN chmod 600 /root/.ssh/id_rsa \
    && ssh-keyscan github.com >> /root/.ssh/known_hosts

WORKDIR /app

COPY . .

RUN chmod +x /app/entrypoint.sh
RUN chmod +x /app/run_ffmpeg.sh

# Clone private repo via SSH
#RUN git clone --depth 1 git@github.com:moshez14/livestream.git 

#WORKDIR livestream
#COPY requirements.txt requirements.txt 
#RUN python3 -m venv /tmp/venv
# Activate venv and install requirements
#RUN source /tmp/venv/bin/activate
#RUN ./venv/bin/pip install --upgrade pip
#RUN /tmp/venv/bin/pip3 install -r requirements.txt
#RUN pip3 install -r requirements.txt

USER 1000

# Start custom-built Nginx in foreground
#CMD ["/usr/local/nginx/sbin/nginx", "-g", "daemon off;"]
#CMD ["/usr/local/nginx/sbin/nginx", "-c", "/etc/nginx/nginx.conf", "-g", "daemon off;"]
ENTRYPOINT ["/app/entrypoint.sh"]
