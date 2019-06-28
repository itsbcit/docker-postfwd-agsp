# Pass as environment variables:
#
#   ENV DB_DBNAME 
#   ENV DB_PASSWORD
#   ENV DB_USERID
#   ENV DB_HOST 
#   ENV DB_PORT
#
# Run container with the following: 
#
# docker run -e DB_DBNAME=DATABASE_NAME -e DB_HOST=DATABASE_HOST -e DB_PORT=3306 -e DB_PASSWORD=DATABASE_PASSWORD -e DB_USERID=DATABASE_USERID bcit/docker-postfwd-agsp:latest

FROM bcit/docker-postfwd:2.02

LABEL maintainer="David_Goodwin@bcit.ca, Juraj Ontkanin"
LABEL version="1.30"

# Use postfwd3 by default
ENV PROG postfwd3

ENV POSTFWD_ANTISPAM_MAIN_CONFIG_PATH=${CONFIGDIR}/anti-spam.conf
ENV POSTFWD_ANTISPAM_SQL_STATEMENTS_CONFIG_PATH=${CONFIGDIR}/anti-spam-sql-st.conf

# Install build tools
# Build and Install modules
# Cleanup
RUN apk --no-cache update \
 && apk --no-cache add  make \
                        wget \
                        gcc \
                        build-base \
                        perl-utils \
                        perl-dev \
                        geoip-dev \
                        postgresql-dev \
                        mysql-dev \
 && cpan    App::cpanminus \
 && cpanm   Geo::IP \
            IO::Handle \
            Config::General \
            Config::Tiny \
            Config::Any::INI \
            Config::Any::General \
            DBI \
            DBD::Pg \
            DBD::mysql \
            Sys::Mmap \
 && apk del make \
            wget \
            gcc \
            build-base \
            perl-utils \
            perl-dev \
 && rm -rf ~/.cpanm

# Download GeoIP dat files 
# Download config files and store in config dir (/config/)
# Download plugin 
RUN mkdir /usr/local/share/GeoIP/ \
 && wget https://raw.githubusercontent.com/Vnet-as/postfwd-anti-geoip-spam-plugin/v1.30/docker/GeoIP.dat \
         https://raw.githubusercontent.com/Vnet-as/postfwd-anti-geoip-spam-plugin/v1.30/docker/GeoIPv6.dat -P /usr/local/share/GeoIP/ \
 && wget https://raw.githubusercontent.com/Vnet-as/postfwd-anti-geoip-spam-plugin/v1.30/anti-spam.conf \
         https://raw.githubusercontent.com/Vnet-as/postfwd-anti-geoip-spam-plugin/v1.30/anti-spam-sql-st.conf -P ${CONFIGDIR} \
 && wget https://raw.githubusercontent.com/Vnet-as/postfwd-anti-geoip-spam-plugin/v1.30/postfwd-anti-spam.plugin -P ${HOME}

# Permissions 
RUN chown postfw:postfw ${HOME}/postfwd-anti-spam.plugin \
 && chown postfw:postfw ${CONFIGDIR}/anti-spam-sql-st.conf \
 && chmod 644 \
          ${HOME}/postfwd-anti-spam.plugin \
          ${CONFIGDIR}/anti-spam-sql-st.conf

EXPOSE ${PORT}

COPY 70-sed-db-settings.sh docker-entrypoint.d/ 

CMD /usr/sbin/${PROG} --file="/etc/postfwd/${CONF}" \
    --user=${USER} --group=${GROUP} \
    --plugins="${HOME}/postfwd-anti-spam.plugin" \
    --server_socket=tcp:${ADDRESS}:${PORT} \
    --cache_socket="unix::${HOME}/postfwd.cache" \
    --cache=${CACHE} \
    --save_rates="${HOME}/postfwd.rates" \
    --save_groups="${HOME}/postfwd.groups" \
    --pidfile="${HOME}/postfwd.pid" \
    --stdout --nodaemon \
    ${EXTRA}
