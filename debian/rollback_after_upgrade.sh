#!/usr/bin/env bash

set -e

INIT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $INIT_DIR/../config.sh
source $INIT_DIR/../bash-utilities/utils.sh
source $INIT_DIR/../mush/mush.sh

LATEST_BACKUP=`ls "$CKAN_BACKUP_PATH" | sort | tail -1`
LATEST_BACKUP_PATH="$CKAN_BACKUP_PATH/$LATEST_BACKUP"
CONFIG_PATH="$CKAN_CONFIG_DIR/production.ini"

service apache2 stop

rm -rf "$VIRTUALENV_DIR" "$CKAN_CONFIG_DIR"
cp -rf "$LATEST_BACKUP_PATH/virtualenv" "$VIRTUALENV_DIR"
cp -rf "$LATEST_BACKUP_PATH/config" "$CKAN_CONFIG_DIR"

deactivate || true
. "$VIRTUALENV_DIR/bin/activate"

paster --plugin=ckan db upgrade -c "$CONFIG_PATH"
paster --plugin=ckan search-index rebuild -r -c "$CONFIG_PATH"

chown -R $OWNER_USER:$OWNER_GROUP $VIRTUALENV_DIR
chown -R $OWNER_USER:$OWNER_GROUP $UPLOADS_DIR

service apache2 start
service jetty restart
