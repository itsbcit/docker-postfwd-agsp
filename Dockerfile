FROM bcit/docker-postfwd:2.02
# vim: syntax=dockerfile

LABEL maintainer="David_Goodwin@bcit.ca, Juraj Ontkanin"
LABEL version="1.30"

ENV CONFIGDIR /config

ENV PROG postfwd3
ENV ADDRESS 0.0.0.0
ENV PORT 10040
ENV CACHE 60
ENV EXTRA "--summary=600 --noidlestats"
ENV CONF postfwd.cf

ENV HOME /var/lib/postfwd
ENV USER postfw 
ENV GROUP postfw
ENV UID 110
ENV GID 110

RUN apk update && apk add \
    make \
    perl-app-cpanminus \
    perl-config-any \
    perl-dbi \
    perl-dbd-mysql \
    perl-dbd-pg

WORKDIR "${CONFIGDIR}"

RUN wget https://raw.githubusercontent.com/Vnet-as/postfwd-anti-geoip-spam-plugin/v1.30/postfwd-anti-spam.plugin \
 && wget https://raw.githubusercontent.com/Vnet-as/postfwd-anti-geoip-spam-plugin/v1.30/anti-spam-sql-st.conf \
 && wget https://raw.githubusercontent.com/Vnet-as/postfwd-anti-geoip-spam-plugin/v1.30/anti-spam.conf \
 && sed -i 's/^logfile =.*/logfile =/' anti-spam.conf \
 && sed -i 's;^geoip_db_path =.*;geoip_db_path = /usr/local/share/GeoIP/GeoIP.dat;' anti-spam.conf

WORKDIR /tmp/

RUN cpanm --no-wget Geo::IP

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
