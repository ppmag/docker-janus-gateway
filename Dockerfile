FROM debian:latest

LABEL maintainer="Linagora Folks <lgs-openpaas-dev@linagora.com>"
LABEL description="Provides an image with Janus Gateway"

RUN apt-get update -y \
    && apt-get upgrade -y

RUN apt-get install -y \
    build-essential \
    libmicrohttpd-dev \
#    libconfig9 \
    ffmpeg \
    libavutil-dev \
    libavcodec-dev \
    libavformat-dev \
    libconfig-dev \
    libjansson-dev \
#    libnice-dev \
    libssl-dev \
    libsofia-sip-ua-dev \
    libglib2.0-dev \
    libopus-dev \
    libogg-dev \
    libini-config-dev \
    libcollection-dev \
    pkg-config \
    gtk-doc-tools \
    gengetopt \
    libtool \
    autotools-dev \
    automake

RUN apt-get install -y \
    sudo \
    make \
    git \
    doxygen \
    graphviz \
    cmake

RUN cd ~ \
    && git clone https://github.com/libnice/libnice.git \
    && cd libnice \
    && sh autogen.sh  \
    && ./configure --prefix=/usr --disable-gtk-doc  \
    && make \
    && sudo make install

RUN cd ~ \
    && git clone https://github.com/cisco/libsrtp.git \
    && cd libsrtp \
#    && git checkout v2.0.0 \
    && ./configure --prefix=/usr --enable-openssl \
    && make shared_library \
    && sudo make install

RUN cd ~ \
    && git clone https://github.com/sctplab/usrsctp \
    && cd usrsctp \
    && ./bootstrap \
    && ./configure --prefix=/usr \
    && make \
    && sudo make install

RUN cd ~ \
    && git clone https://github.com/warmcat/libwebsockets.git \
    && cd libwebsockets \
#    && git checkout v2.1.0 \
    && mkdir build \
    && cd build \
    && cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr -DLWS_IPV6=ON .. \
    && make \
    && sudo make install

RUN cd ~ \
    && git clone https://github.com/alanxz/rabbitmq-c.git \
    && cd rabbitmq-c \
#    && git checkout v2.1.0 \
    && git submodule init \
    && git submodule update \
    && mkdir build \
    && cd build \
    && cmake .. \
    && cmake --build . \
    && cmake -DCMAKE_INSTALL_PREFIX=/usr/local .. \
    && cmake --build .  --target install

RUN cd ~ \
    && git clone https://github.com/eclipse/paho.mqtt.c.git \
    && cd paho.mqtt.c \
    && make \
    && sudo make install

RUN cd ~ \
    && git clone https://github.com/meetecho/janus-gateway.git \
    && cd janus-gateway \
    && sh autogen.sh \
    && ./configure --prefix=/opt/janus --enable-libsrtp2 --enable-post-processing --disable-docs \
    && make CFLAGS='-std=c99' \
    && make install \
    && make configs


RUN apt-get install nginx -y

#RUN cp -rp ~/janus-gateway/certs /opt/janus/share/janus
COPY cert/*.* /opt/janus/share/janus/certs/

COPY conf/*.jcfg /opt/janus/etc/janus/

# copy demo sources to container 
COPY html /root/janus-gateway/

COPY util/convert-mjr-to-webm.sh /opt/janus/share/janus/recordings/
RUN  chmod +x /opt/janus/share/janus/recordings/convert-mjr-to-webm.sh

RUN  mkdir /opt/janus/share/janus/recordings/list

COPY nginx/nginx.conf /etc/nginx/nginx.conf

EXPOSE 80 443 7088 8088 8089 8188 
EXPOSE 10000-10200/udp

CMD sudo nginx -t && service nginx restart \
    && /opt/janus/bin/janus -F /opt/janus/etc/janus -C /opt/janus/etc/janus/janus.jcfg --nat-1-1=${DOCKER_IP}
