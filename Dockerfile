FROM bcit/docker-postfwd:2.02
# vim: syntax=dockerfile

LABEL maintainer="David_Goodwin@bcit.ca, Juraj Ontkanin"
LABEL version="1.30"

ENV DOCKERIZE_ENV production

ENV CONFIGDIR /config

ENV PROG postfwd3
ENV ADDRESS 0.0.0.0
ENV PORT 10040
ENV CACHE 60
ENV EXTRA "--summary=600 --noidlestats"
ENV CONF postfwd.cf

ENV POSTFWD_ANTISPAM_MAIN_CONFIG_PATH /etc/postfwd/anti-spam.conf
ENV POSTFWD_ANTISPAM_SQL_STATEMENTS_CONFIG_PATH /etc/postfwd/anti-spam-sql-st.conf

ENV HOME /var/lib/postfwd
ENV USER postfw 
ENV GROUP postfw
ENV UID 110
ENV GID 110

RUN apk --no-cache update \
 && apk --no-cache add \
    make \
    gcc \
    perl-dev \
    musl-dev \
    geoip-dev \
    perl-app-cpanminus \
    perl-config-any \
    perl-config-tiny \
    perl-dbi \
    perl-dbd-mysql \
    perl-dbd-pg \
    perl-sys-mmap

RUN cpanm --no-wget \
    Geo::IP \
    Config::General \
 && rm -rf ~/.cpanm

RUN mkdir -p "$CONFIGDIR"

WORKDIR /etc/postfwd

RUN wget https://raw.githubusercontent.com/Vnet-as/postfwd-anti-geoip-spam-plugin/v1.30/postfwd-anti-spam.plugin \
 && wget https://raw.githubusercontent.com/Vnet-as/postfwd-anti-geoip-spam-plugin/v1.30/anti-spam-sql-st.conf \
 && wget https://raw.githubusercontent.com/Vnet-as/postfwd-anti-geoip-spam-plugin/v1.30/anti-spam.conf \
 && sed -i "s;^logfile\s*=.*;logfile =;g" anti-spam.conf \
 && sed -i "s/^debug\s*=.*/debug = 1/g" anti-spam.conf \
 && sed -i "s;^geoip_db_path\s*=.*;geoip_db_path = /usr/local/share/GeoIP/GeoIP.dat;" anti-spam.conf

RUN mkdir -p /usr/local/share/GeoIP
COPY GeoIP*.dat /usr/local/share/GeoIP/

WORKDIR /

EXPOSE ${PORT}

CMD /usr/sbin/${PROG} --file="/etc/postfwd/${CONF}" \
    --plugins /etc/postfwd/postfwd-anti-spam.plugin \
    --user=${USER} --group=${GROUP} \
    --server_socket=tcp:${ADDRESS}:${PORT} \
    --cache_socket="unix::${HOME}/postfwd.cache" \
    --cache=${CACHE} \
    --save_rates="${HOME}/postfwd.rates" \
    --save_groups="${HOME}/postfwd.groups" \
    --pidfile="${HOME}/postfwd.pid" \
    ${EXTRA} \
    --stdout --nodaemon
