sed -i "1,/test/s/test/$DB_DBNAME/" ${CONFIGDIR}/anti-spam.conf \
 && sed -i "s/localhost/$DB_HOST/" ${CONFIGDIR}/anti-spam.conf \
 && sed -i "s/3306/$DB_PORT/" ${CONFIGDIR}/anti-spam.conf \
 && sed -i "s/= password/= $DB_PASSWORD/" ${CONFIGDIR}/anti-spam.conf \
 && sed -i "s/testuser/$DB_USERID/" ${CONFIGDIR}/anti-spam.conf 