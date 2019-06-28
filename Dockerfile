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

## DATABASE
ENV DB_DRIVER mysql
ENV DB_HOST localhost
ENV DB_PORT 3306
ENV DB_DATABASE test
ENV DB_USER testuser
ENV DB_PWD password

## LOGGING
ENV LOGFILE ''
ENV AUTOFLUSH 0

## DEBUGGING
ENV DEBUG 1
ENV COUNTRY_LIMIT 5
ENV IP_LIMIT 20

## APP
ENV DB_FLUSH_INTERVAL 86400
ENV GEOIP_DB_PATH "/usr/local/share/GeoIP/GeoIP.dat"

ENV HOME /var/lib/postfwd
ENV USER postfw 
ENV GROUP postfw
ENV UID 110
ENV GID 110

RUN apk --no-cache update \
 && apk --no-cache add \
    # wget \
    make \
    gcc \
    perl-dev \
    musl-dev \
    # geoip \
    geoip-dev \
    # build-base \
    # perl-utils \
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
    # IO::Handle \
 && rm -rf ~/.cpanm

WORKDIR "${CONFIGDIR}"

RUN wget https://raw.githubusercontent.com/Vnet-as/postfwd-anti-geoip-spam-plugin/v1.30/postfwd-anti-spam.plugin \
 && wget https://raw.githubusercontent.com/Vnet-as/postfwd-anti-geoip-spam-plugin/v1.30/anti-spam-sql-st.conf \
 && wget https://raw.githubusercontent.com/Vnet-as/postfwd-anti-geoip-spam-plugin/v1.30/anti-spam.conf \
 ## DATABASE
 && sed -i "s/^driver\s*=.*/driver = $DB_DRIVER/g" anti-spam.conf \
 && sed -i "s/^database\s*=.*/database = $DB_DATABASE/g" anti-spam.conf \
 && sed -i "s/^host\s*=.*/host = $DB_HOST/g" anti-spam.conf \
 && sed -i "s/^port\s*=.*/port = $DB_PORT/g" anti-spam.conf \
 && sed -i "s/^userid\s*=.*/userid = $DB_USER/g" anti-spam.conf \
 && sed -i "s/^password\s*=.*/userid = $DB_PWD/g" anti-spam.conf \
 ## LOGGING
 && sed -i "s;^logfile\s*=.*;logfile = $LOGFILE;g" anti-spam.conf \
 && sed -i "s/^autoflush\s*=.*/autoflush = $AUTOFLUSH/g" anti-spam.conf \
 ## DEBUG
 && sed -i "s/^debug\s*=.*/debug = $DEBUG/g" anti-spam.conf \
 && sed -i "s/^country_limit\s*=.*/country_limit = $COUNTRY_LIMIT/g" anti-spam.conf \
 && sed -i "s/^ip_limit\s*=.*/ip_limit = $IP_LIMIT/g" anti-spam.conf \
 ## APP
 && sed -i "s/^db_flush_interval\s*=.*/db_flush_interval = $DB_FLUSH_INTERVAL/g" anti-spam.conf \
 && sed -i "s;^geoip_db_path\s*=.*;geoip_db_path = $GEOIP_DB_PATH;" anti-spam.conf \
 ## PLUGIN
 && sed -i 's;/etc/postfix/;/etc/postfwd/;g' postfwd-anti-spam.plugin

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
