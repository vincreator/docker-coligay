FROM ubuntu:20.04

# Set time zone to your local time zone
ENV TZ=Asia/Jakarta
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Set debconf to use noninteractive frontend
ENV DEBIAN_FRONTEND noninteractive

# Install Golang and dependencies
RUN apt-get update && apt-get install -y \
    git \
    libffi-dev \
    libssl-dev \
    python3-dev \
    python3-pip \
    zlib1g-dev \
    libtiff5-dev \
    libjpeg-dev \
    libwebp-dev \
    libfreetype6-dev \
    liblcms2-dev \
    libopenjp2-7-dev \
    libpng-dev \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    golang-go \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages using pip
RUN python3 -m pip install --upgrade pip
RUN python3 -m pip install wheel aiohttp uvloop

# Install curl, neofetch, and libnss3
RUN apt-get update && apt-get install -y \
    curl \
    neofetch \
    libnss3 \
    && rm -rf /var/lib/apt/lists/*

# Install native dependencies
RUN apt-get update && apt-get install -y \
    libffi7 \
    libssl1.1 \
    libtiff5 \
    libfreetype6 \
    libjpeg-turbo8 \
    liblcms2-2 \
    libwebp6 \
    libopenjp2-7 \
    libpng16-16 \
    busybox \
    sqlite3 \
    libxml2 \
    libssh2-1 \
    ca-certificates \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Install aria2 with SFTP and GZIP support
RUN apt-get update && apt-get install -y \
    aria2 \
    && rm -rf /var/lib/apt/lists/*

RUN aria2c https://github.com/tatsuhiro-t/nghttp2/releases/download/v1.41.0/nghttp2-1.41.0.tar.gz -o nghttp2.tar.gz
RUN tar -zxvf nghttp2.tar.gz
RUN cd nghttp2-1.41.0 && ./configure && make && make install

RUN aria2c https://github.com/libssh2/libssh2/releases/download/libssh2-1.9.0/libssh2-1.9.0.tar.gz -o libssh2.tar.gz
RUN tar -zxvf libssh2.tar.gz
RUN cd libssh2-1.9.0 && ./configure && make && make install

# Install mkcert
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN curl -L https://github.com/FiloSottile/mkcert/releases/download/v1.4.2/mkcert-v1.4.2-linux-amd64 -o mkcert
RUN chmod +x mkcert
RUN mv mkcert /usr/local/bin
