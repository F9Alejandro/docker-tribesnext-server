# Multi-Stage Build (TacoServer)
# This stage compiles the various resources that make up TacoServer
FROM alpine:3.10 as tacobuilder

RUN apk --update add git sed less wget nano openssh && \
    rm -rf /var/lib/apt/lists/* && \
    rm /var/cache/apk/*

WORKDIR /tmp

RUN git clone --depth 1 "https://github.com/ChocoTaco1/TacoServer/" && cd ./TacoServer
WORKDIR /tmp

RUN git clone --depth 1 "https://github.com/ChocoTaco1/TacoMaps/"  && cd ./TacoMaps 
WORKDIR /tmp


# Main Game Server Image
FROM i386/ubuntu:disco
LABEL maintainer="sairuk, amineo, chocotaco"

# ENVIRONMENT
ARG SRVUSER=gameserv
ARG SRVUID=1000
ARG SRVDIR=/tmp/tribes2/
ENV INSTDIR=/home/${SRVUSER}/.wine32/drive_c/Dynamix/Tribes2/

# WINE VERSION: wine = 1.6, wine-development = 1.7.29 for i386-jessie
ENV WINEVER=wine-development
ENV WINEARCH=win32
ENV WINEPREFIX=/home/${SRVUSER}/.wine32/

#WINEARCH=win32 WINEPREFIX=/home/gameserv/.wine32/ wine wineboot

# UPDATE IMAGE
RUN dpkg --add-architecture i386
RUN apt-get -y update && apt-get -y upgrade

# DEPENDENCIES
RUN apt-get -y install \
# -- access
sudo unzip \
# -- logging
rsyslog \
# -- utilities
sed less nano vim file wget gnupg2 software-properties-common git \
# --- wine
#${WINEVER} \
# -- display
xvfb

# GET WINE
RUN wget --no-check-certificate https://dl.winehq.org/wine-builds/winehq.key
RUN apt-key add winehq.key
RUN add-apt-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ disco main'
RUN add-apt-repository ppa:cybermax-dexter/sdl2-backport
RUN apt-get -y update && apt-get -y upgrade && apt-get -y install --install-recommends winehq-devel


# INSTALL GAMEMODE
#RUN add-apt-repository ppa:samoilov-lex/gamemode
#RUN apt-get -y update && apt-get -y install dbus-user-session gamemode


# BUILD WINE FROM SOURCE
#RUN apt-get -y remove winehq-devel
#RUN apt-get install -y flex bison gcc-multilib xserver-xorg-dev libgstreamer1.0-dev \
#libgstreamer-plugins-base1.0-dev libxcursor-dev libxi-dev libxxf86vm-dev libxrandr-dev libxfixes-dev \
#libxinerama-dev libxcomposite-dev libglu1-mesa-dev libosmesa6-dev opencl-headers libpcap-dev libdbus-1-dev \
#libncurses5-dev libsane-dev libv4l-dev libgphoto2-dev libpulse-dev libudev-dev libcups2-dev libfontconfig1-dev \
#libgsm1-dev libmpg123-dev libopenal-dev libldap2-dev libxrender-dev libopengl0 libxslt1-dev libgnutls28-dev \
#libjpeg-dev libva-dev xorg-dev libx11-dev libx11-dev:i386 libfreetype6-dev:i386 winbind gstreamer-1.0 \
#libgstreamer-plugins-base1.0-dev:i386
#RUN git clone git://source.winehq.org/git/wine.git ~/wine-dirs/wine-source
#RUN cd ~/wine-dirs/wine-source
#RUN sh ~/wine-dirs/wine-source/configure --prefix=/usr --libdir=/usr/lib --with-x --with-gstreamer --enable-win64
#RUN sh ~/wine-dirs/wine-source/configure --prefix=/usr --libdir=/usr/lib32 --with-x
#RUN make -j4 
#RUN make install


# CLEAN IMAGE
RUN apt-get -y clean && apt-get -y autoremove


# ENV
# -- shutup installers
ENV DEBIAN_FRONTEND noninteractive

# USER
# -- add the user, expose datastore
RUN useradd -m -s /bin/bash -u ${SRVUID} ${SRVUSER}
# -- temporarily steal ownership
RUN chown -R root: /home/${SRVUSER}
# -- set wine win32 env
RUN WINEARCH=win32 WINEPREFIX=/home/gameserv/.wine32/ wine wineboot

# SCRIPT - installer
COPY _scripts/tribesnext-server-installer ${SRVDIR}
RUN chmod +x ${SRVDIR}/tribesnext-server-installer
RUN ${SRVDIR}/tribesnext-server-installer


# SCRIPT - server (default)
COPY _scripts/start-server ${INSTDIR}/start-server
RUN chmod +x ${INSTDIR}/start-server


# CLEAN UP TMP
COPY _scripts/clean-up ${SRVDIR}
RUN chmod +x ${SRVDIR}/clean-up
RUN ${SRVDIR}/clean-up


# TacoServer - Pull in resources from builder
COPY --from=tacobuilder /tmp/TacoServer/Classic/. ${INSTDIR}GameData/Classic/.
COPY --from=tacobuilder /tmp/TacoMaps/. ${INSTDIR}GameData/Classic/Maps/


# SCRIPT - custom (custom content / overrides)
COPY _custom/. ${INSTDIR}


# SCRIPT - expand admin prefs
COPY _scripts/cfg-admin-prefs ${SRVDIR}
RUN chmod +x ${SRVDIR}/cfg-admin-prefs


# PERMISSIONS
RUN chown -R ${SRVUSER}: /home/${SRVUSER}


# PORTS
EXPOSE \
# -- tribes
666/tcp \
28000/udp 

USER ${SRVUSER}
WORKDIR ${INSTDIR}

CMD ["./start-server"]

