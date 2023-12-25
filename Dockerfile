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

RUN git clone --depth 1 "https://github.com/ChocoTaco1/NoTNscripts/"  && cd ./NoTNscripts


# Main Game Server Image
FROM i386/debian:bookworm
LABEL maintainer="sairuk, battlelore, chocotaco"

# ENVIRONMENT
ARG SRVUSER=container
ARG SRVUID=1000
ARG SRVDIR=/tmp/tribes2/
ENV INSTDIR=/home/${SRVUSER}/.loki/tribes2/
#ENV TZ="America/New_York"
# -- shutup installers
ENV DEBIAN_FRONTEND noninteractive


# UPDATE IMAGE
RUN dpkg --add-architecture i386
RUN apt-get -y update --fix-missing && apt-get -y upgrade

# DEPENDENCIES
RUN apt-get -y install \
# -- access
sudo unzip \
# -- logging
rsyslog \
# -- utilities
sed less nano vim file wget curl gnupg2 netcat-traditional software-properties-common xdelta3 tzdata

#RUN timedatectl set-timezone ${TZ}

# CLEAN IMAGE
RUN apt-get -y clean && apt-get -y autoremove

# USER
# -- add the user, expose datastore
RUN adduser -D -h /home/container container
# -- temporarily steal ownership
RUN chown -R root: /home/${SRVUSER}


# SCRIPT - installer
COPY _scripts/tribesnext-server-installer ${SRVDIR}
RUN chmod +x ${SRVDIR}/tribesnext-server-installer
RUN ${SRVDIR}/tribesnext-server-installer


# SCRIPT - server (default)
COPY _scripts/start-server ${INSTDIR}/start-server
RUN chmod +x ${INSTDIR}/start-server

# TacoServer - Pull in resources from builder
COPY --from=tacobuilder /tmp/TacoServer/Classic/. ${INSTDIR}/Classic/.
COPY --from=tacobuilder /tmp/TacoMaps/. ${INSTDIR}/Classic/Maps/
COPY --from=tacobuilder /tmp/NoTNscripts/. ${INSTDIR}/Classic/.


# CLEAN UP
COPY _scripts/clean-up ${SRVDIR}
RUN chmod +x ${SRVDIR}/clean-up
RUN ${SRVDIR}/clean-up ${INSTDIR}


# SCRIPT - custom (custom content / overrides)
COPY _custom/. ${INSTDIR}


# SCRIPT - expand admin prefs
COPY _scripts/cfg-admin-prefs ${SRVDIR}
RUN chmod +x ${SRVDIR}/cfg-admin-prefs

# SCRIPT - generate our alphabetized autoexec index
COPY _scripts/gen_autoexec_index ${SRVDIR}
RUN chmod +x ${SRVDIR}/gen_autoexec_index

# SCRIPT - heartbeat to TribesNext's master server
COPY _scripts/tn_heartbeat ${SRVDIR}
RUN chmod +x ${SRVDIR}/tn_heartbeat


# PERMISSIONS
RUN chown -R ${SRVUSER}: /home/${SRVUSER}


# PORTS
EXPOSE \
# -- tribes
666/tcp \
28000/udp

USER ${SRVUSER}
ENV USER=container HOME=/home/container
WORKDIR /home/${SRVUSER}

COPY --chown=container:container ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
CMD ["/bin/bash","/entrypoint.sh"]

