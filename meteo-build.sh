#!/bin/bash

export NAME="bacularis"
export BACULARIS_VERSION="6.0.0"
wget https://github.com/bacularis/bacularis-app/archive/refs/tags/${BACULARIS_VERSION}.tar.gz -O bacularis-app-${BACULARIS_VERSION}.tar.gz
wget https://github.com/bacularis/bacularis-common/archive/refs/tags/${BACULARIS_VERSION}.tar.gz -O bacularis-common-${BACULARIS_VERSION}.tar.gz
wget https://github.com/bacularis/bacularis-api/archive/refs/tags/${BACULARIS_VERSION}.tar.gz -O bacularis-api-${BACULARIS_VERSION}.tar.gz
wget https://github.com/bacularis/bacularis-web/archive/refs/tags/${BACULARIS_VERSION}.tar.gz -O bacularis-web-${BACULARIS_VERSION}.tar.gz
wget https://bacularis.app/downloads/bacularis-external-${BACULARIS_VERSION}.tar.gz -O bacularis-external-${BACULARIS_VERSION}.tar.gz

#exit 0
for component in bacularis-external bacularis-app bacularis-common bacularis-api bacularis-web; do mkdir -pv ${component} ; tar -C ${component} --strip-components=1 -zxvf ${component}-${BACULARIS_VERSION}.tar.gz;done

mkdir -p          "${NAME}/protected/vendor/${NAME}/${NAME}-common" \
                        "${NAME}/protected/vendor/${NAME}/${NAME}-api" \
                        "${NAME}/protected/vendor/${NAME}/${NAME}-web" \
                        "${NAME}/protected/runtime" \
                        "${NAME}/htdocs/assets"
cp -a "${NAME}-common/project/"* "${NAME}/"
cp -r "${NAME}-common/"* "${NAME}/protected/vendor/${NAME}/${NAME}-common/"
cp -r "${NAME}-api/"* "${NAME}/protected/vendor/${NAME}/${NAME}-api/"
cp -r "${NAME}-web/"* "${NAME}/protected/vendor/${NAME}/${NAME}-web/"
cp -r "${NAME}-external/vendor/"* "${NAME}/protected/vendor/"
cp "${NAME}/protected/samples/webserver/${NAME}.users.sample" "${NAME}/protected/vendor/${NAME}/${NAME}-api/API/Config/${NAME}.users"
cp "${NAME}/protected/samples/webserver/${NAME}.users.sample" "${NAME}/protected/vendor/${NAME}/${NAME}-web/Web/Config/${NAME}.users"
ln -sf "vendor/${NAME}/${NAME}-common/Common" "${NAME}/protected/"
ln -sf "vendor/${NAME}/${NAME}-api/API" "${NAME}/protected/"
ln -sf "vendor/${NAME}/${NAME}-web/Web" "${NAME}/protected/"
cp "${NAME}/protected/vendor/npm-asset/fortawesome--fontawesome-free/css/all.min.css" "${NAME}/htdocs/themes/Baculum-v2/fonts/css/fontawesome-all.min.css"
cp -r "${NAME}/protected/vendor/npm-asset/fortawesome--fontawesome-free/webfonts/"* "${NAME}/htdocs/themes/Baculum-v2/fonts/webfonts/"

