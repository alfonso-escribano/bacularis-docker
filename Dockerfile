FROM debian:trixie-slim

LABEL maintainer="Alfonso Escribano <alfonso.escribano@meteologica.com>"

ENV BACULARIS_VERSION=6.3.0
ENV PACKAGE_NAME=standalone
ENV PHP_VERSION=8.4
ENV WEB_USER=bacula

RUN groupadd -g 26 tape; \
	groupadd -g 124 bacula; \
	useradd -r -d /var/lib/bacula -s /usr/sbin/nologin -g bacula -G tape -u 117 bacula
#RUN groupadd -g 30 tape; \
#	groupadd -g 133 bacula; \
#	useradd -r -d /var/lib/bacula -s /sbin/nologin -g bacula -G tape -u 133 bacula

RUN apt update && \
	apt -y install --no-install-recommends bacula-common && \
	if [ "${PACKAGE_NAME}" = 'standalone' ] || [ "${PACKAGE_NAME}" = 'api-dir' ]; then \
		DEBIAN_FRONTEND=noninteractive apt -y install --no-install-recommends dbconfig-no-thanks; \
		DEBIAN_FRONTEND=noninteractive apt -y install --no-install-recommends postgresql-client-common; \
		echo "create_main_cluster = false" > /etc/postgresql-common/createcluster.conf; \
		mkdir /etc/dbconfig-common; \
                echo "dbc_install=false\ndbc_dbtype=pgsql\ndbc_name=bacula\ndbc_address=localhost\ndbc_dbuser=bacula\ndbc_dbpassword=" > /etc/dbconfig-common/bacula-director-pgsql.conf; \
		DEBIAN_FRONTEND=noninteractive apt -y install --no-install-recommends bacula-common-pgsql bacula-director-pgsql bacula-director bacula-console; \
		sed -i 's!XXX_DBNAME_XXX!bacula!g; s!XXX_DBUSER_XXX!bacula!g; s!XXX_DBPASSWORD_XXX!bacula!g; /DirAddress = 127.0.0.1/d' /etc/bacula/bacula-dir.conf; \
	fi && \
	if [ "${PACKAGE_NAME}" = 'standalone' ] || [ "${PACKAGE_NAME}" = 'api-sd' ]; then \
		DEBIAN_FRONTEND=noninteractive apt -y install --no-install-recommends bacula-sd mtx mt-st; \
		mkdir 770 /var/lib/bacula/archive; \
		chown bacula:tape /var/lib/bacula/archive; \
		sed -i 's!/nonexistant/path/to/file/archive/dir!/var/lib/bacula/archive!g; /SDAddress = 127.0.0.1/d' /etc/bacula/bacula-sd.conf; \
	fi && \
	if [ "${PACKAGE_NAME}" = 'standalone' ] || [ "${PACKAGE_NAME}" = 'api-fd' ]; then \
		DEBIAN_FRONTEND=noninteractive apt -y install --no-install-recommends bacula-fd; \
		sed -i '/FDAddress = 127.0.0.1/d' /etc/bacula/bacula-fd.conf; \
	fi && \
	if [ "${PACKAGE_NAME}" = 'standalone' ] || [ "${PACKAGE_NAME}" = 'web' ]; then \
		DEBIAN_FRONTEND=noninteractive apt -y install --no-install-recommends expect gnupg openssh-client; \
	fi && \
	chown root:bacula /etc/bacula && \
	chmod 775 /etc/bacula && \
	chmod 660 /etc/bacula/*.conf || true && \
	DEBIAN_FRONTEND=noninteractive apt -y install --no-install-recommends nginx && \
	usermod -a -G bacula ${WEB_USER} && \
	DEBIAN_FRONTEND=noninteractive apt -y install --no-install-recommends sudo php-bcmath php-curl php-dom php-json php-ldap php-pgsql php-pgsql php-mysql php-intl php-fpm && \
	DEBIAN_FRONTEND=noninteractive apt -y -f install

RUN apt-get autoremove -y \
    && apt-get clean -y \
    && apt-get autoclean -y \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 9097/tcp

COPY "docker/systems/debian/sudoers.d/bacularis-${PACKAGE_NAME}" /etc/sudoers.d/

COPY "docker/systems/debian/entrypoint/docker-entrypoint.inc"  /

COPY "docker/systems/debian/entrypoint/docker-entrypoint-${PACKAGE_NAME}.sh" /docker-entrypoint.sh

COPY bacularis /var/www/bacularis

COPY "docker/systems/debian/config/API/api-${PACKAGE_NAME}.conf" /var/www/bacularis/protected/vendor/bacularis/bacularis-api/API/Config/api.conf

COPY --chown=${WEB_USER}:${WEB_USER} common/config/API/* /var/www/bacularis/protected/vendor/bacularis/bacularis-api/API/Config/

COPY --chown=${WEB_USER}:${WEB_USER} common/config/Web/* /var/www/bacularis/protected/vendor/bacularis/bacularis-web/Web/Config/

RUN if [ "${PACKAGE_NAME}" = 'web' ]; then \
		rm /var/www/bacularis/protected/vendor/bacularis/bacularis-api/API/Config/*.conf; \
		rm /var/www/bacularis/protected/vendor/bacularis/bacularis-web/Web/Config/*.conf; \
		sed -i '/service id="oauth"/d; /service id="api"/d; /service id="panel"/d; s!BasePath="Bacularis.Common.Pages"!BasePath="Bacularis.Web.Pages"!; s!DefaultPage="CommonPage"!DefaultPage="Dashboard"!;' /var/www/bacularis/protected/application.xml; \
	fi && \
	if [ "${PACKAGE_NAME}" = 'api-dir' ] || [ "${PACKAGE_NAME}" = 'api-sd' ] || [ "${PACKAGE_NAME}" = 'api-fd' ]; then \
		rm /var/www/bacularis/protected/vendor/bacularis/bacularis-web/Web/Config/*.conf; \
		sed -i 's!BasePath="Bacularis.Common.Pages"!BasePath="Bacularis.API.Pages.Panel"!; s!DefaultPage="CommonPage"!DefaultPage="APIHome"!; /service id="web"/d;' /var/www/bacularis/protected/application.xml; \
	fi && \
	/var/www/bacularis/protected/tools/install.sh -w nginx -c /etc/nginx/sites-available -u ${WEB_USER} -d /var/www/bacularis/htdocs -p /var/run/php/php${PHP_VERSION}-fpm.sock && \
	mv /etc/nginx/sites-available/bacularis-nginx.conf /etc/nginx/sites-available/bacularis.conf; \
	ln -s /etc/nginx/sites-available/bacularis.conf /etc/nginx/sites-enabled/; \
	rm -f /etc/nginx/sites-enabled/default; \
	sed -i -e 's/user www-data;/user bacula;/g' /etc/nginx/nginx.conf; \
	sed -i -e 's/group = www-data/group = tape/g' /etc/php/8.4/fpm/pool.d/www.conf; \
	sed -i -e 's/user = www-data/user = bacula/g' /etc/php/8.4/fpm/pool.d/www.conf; \
	sed -i -e 's/listen.owner = www-data/listen.owner = bacula/g' /etc/php/8.4/fpm/pool.d/www.conf; \
	sed -i -e 's/listen.group = www.data/liste.group = tape/g' /etc/php/8.4/fpm/pool.d/www.conf


VOLUME ["/etc/bacula", "/var/lib/bacula","/var/spool/bacula","/var/www/bacularis/protected/vendor/bacularis/bacularis-api/API/Config", "/var/www/bacularis/protected/vendor/bacularis/bacularis-api/API/Logs", "/var/www/bacularis/protected/vendor/bacularis/bacularis-web/Web/Config", "/var/www/bacularis/protected/vendor/bacularis/bacularis-web/Web/Logs", "/var/www/bacularis/protected/vendor/bacularis/bacularis-common/Common/Working" ]

ENTRYPOINT [ "/docker-entrypoint.sh" ]

CMD ["nginx", "-g", "daemon off;"]
