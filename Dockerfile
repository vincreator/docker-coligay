FROM ubuntu:20.04

# Set time zone to your local time zone
ENV TZ=Asia/Jakarta
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Set debconf to use noninteractive frontend
ENV DEBIAN_FRONTEND noninteractive

# Install Git and other dependencies needed to build Go programs
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    golang-go

# Build Python package and dependencies
FROM python:3.9-slim-buster AS python-build
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
    libpng-dev
RUN mkdir -p /opt/venv
WORKDIR /opt/venv
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN mkdir -p /src
WORKDIR /src

# Install bot package and dependencies
COPY . .
RUN pip install --upgrade pip
RUN pip install wheel
RUN pip install aiohttp[speedups]
RUN pip install uvloop
RUN pip install .

# Package everything
FROM python:3.9-slim-buster AS final
# Update system first
RUN apt-get update

# Install optional native tools (for full functionality)
RUN apt-get update && apt-get install -y \
    curl \
    neofetch \
    git \
    libnss3

# Install native dependencies
RUN apt-get update && apt-get install -y \
    libffi6 \
    libssl1.1 \
    libtiff5 \
    libfreetype6 \
    libjpeg62-turbo \
    liblcms2-2 \
    libwebp6 \
    libopenjp2-7 \
    libpng16-16 \
    busybox \
    sqlite3 \
    libxml2 \
    libssh2-1 \
    ca-certificates \
    ffmpeg

# Create bot user
RUN adduser -D caligo

# Copy Python venv
ENV PATH="/opt/venv/bin:$PATH"
COPY --from=python-build /opt/venv /opt/venv

# Tell system that we run on container
ENV CONTAINER="True"

# Clone the repo so update works
RUN git clone https://github.com/adekmaulana/caligo /home/caligo
RUN chmod +x /home/caligo/bot
RUN cp /home/caligo/bot /usr/local/bin

# Download aria with sftp and gzip support
ARG ARIA2=aria2_1.36.0-1_amd64.deb
RUN curl -LJO https://raw.githubusercontent.com/adekmaulana/docker/master/aria2/$ARIA2
RUN apt-get update && apt-get install -y ./$ARIA2

# Certs for aria2 https websocket
RUN mkdir -p /home/caligo/.cache/caligo/.certs

# Initialize mkcert
RUN curl -LJO https://github.com/FiloSottile/mkcert/releases/download/v1.4.3/mkcert-v1.4.3-linux-amd64
RUN mv mkcert-v1.4.3-linux-amd64 /usr/local/bin/mkcert
RUN chmod +x /usr/local/bin/mkcert

RUN mkcert -install
RUN mkcert -key-file /home/caligo/.cache/caligo/.certs/key.pem -cert-file /home/caligo/.cache/caligo/.certs/cert.pem localhost 127.0.0.1

# Change permission of home folder
RUN chown -hR caligo /home/caligo

# Set runtime settings
USER caligo
WORKDIR /home/caligo
CMD ["bash", "bot"]
