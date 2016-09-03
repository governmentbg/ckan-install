#!/usr/bin/env bash

# A script for upgrading our custom CKAN install from 2.3.x to 2.5.1
#
# =======
# UPGRADE
# =======
#
# 1. Clone this repo somewhere as root
# 2. Make sure you have the same config.sh as used by the installation. If not,
#    copy config.sh.sample to config.sh and edit it accordingly to match your
#    current CKAN installation.
# 3. Add the following to config.sh:
#
#    CKAN_BACKUP_PATH=/var/www/ckan/backup
#
#    (or set it to a path you prefer.)
# 4. Set CKAN_REPO_TAG in config.sh to the appropriate value to the desired
#    CKAN version. For example:
#
#    CKAN_REPO_TAG=https://github.com/ckan/ckan.git@ckan-2.5.1
#
# ==================
# ROLLBACK / RESTORE
# ==================
#
# Run the following:
#
#   ./debian/rollback_after_upgrade.sh

set -e

INIT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $INIT_DIR/../config.sh
source $INIT_DIR/../bash-utilities/utils.sh
source $INIT_DIR/../mush/mush.sh

OPENDATA_CONFIG_LINK=/etc/nginx/sites-enabled/opendatabulgaria
OPENDATA_CONFIG=/etc/nginx/sites-available/opendatabulgaria

# Prepare a maintenance page
MAINTENANCE_WEBROOT_DIR=`dirname $VIRTUALENV_DIR`
MAINTENANCE_WEBROOT_DIR=`dirname $MAINTENANCE_WEBROOT_DIR`/maintenance
MAINTENANCE_CONFIG='/etc/nginx/sites-enabled/maintenance.conf'
mkdir -p "$MAINTENANCE_WEBROOT_DIR"
cp -f "$INIT_DIR/maintenance/index.html" "$MAINTENANCE_WEBROOT_DIR"

rm -fv "$OPENDATA_CONFIG_LINK"

echo 'Enabling maintenance mode...'
export MAINTENANCE_WEBROOT_DIR CKAN_DOMAIN
cat "$INIT_DIR/maintenance/maintenance.conf" | mush > $MAINTENANCE_CONFIG
echo "Reloading Nginx to enable maintenance mode..."
service nginx restart

service apache2 stop

# activate virtualenv
. "$VIRTUALENV_DIR/bin/activate"


# Backup old version
CURRENT_BACKUP_DIR="$CKAN_BACKUP_PATH/$(date '+%Y%m%d_%H%M%S')"
mkdir -p $CURRENT_BACKUP_DIR
cd $CURRENT_BACKUP_DIR

# Database backup
PG_OPENDATA_BACKUP_NAME="backup_opendata_$(date '+%Y%m%d').dump"
PG_OPENDATA_DATASTORE_BACKUP_NAME="backup_opendata_datastore_$(date '+%Y%m%d').dump"

sudo -u postgres pg_dump opendata > $PG_OPENDATA_BACKUP_NAME
sudo -u postgres pg_dump opendata_datastore > $PG_OPENDATA_DATASTORE_BACKUP_NAME
paster --plugin=ckan db dump --config=/var/www/ckan/config/production.ini opendata_`date '+%Y%m%d_%H%M%S'`.pg_dump

cp -r $CKAN_CONFIG_DIR $CURRENT_BACKUP_DIR
cp -r $VIRTUALENV_DIR $CURRENT_BACKUP_DIR

cd $CURRENT_BACKUP_DIR
mkdir nginx
cd nginx
cp /etc/nginx/nginx.conf .
cp /etc/nginx/sites-available/opendatabulgaria .

cd $CURRENT_BACKUP_DIR
mkdir apache2
cd apache2
cp /etc/apache2/sites-available/opendatabulgaria .
cp /etc/apache2/sites-available/opendatabulgaria_datapusher .


# Remove current version of ckan
pip uninstall ckan
rm -rf "$VIRTUALENV_DIR/src/ckan/"
pip uninstall datapusher
rm -rf "$VIRTUALENV_DIR/src/datapusher/"
pip uninstall ckanext-bulgarian-theme
rm -rf "$VIRTUALENV_DIR/src/bulgarian-theme"

deactivate
. "$VIRTUALENV_DIR/bin/activate"
pip install --upgrade setuptools
pip install --upgrade pip
deactivate
. "$VIRTUALENV_DIR/bin/activate"

# install ckan, data.government.bg theme, and datapusher to virtualenv
pip install -e "git+$CKAN_REPO_TAG#egg=ckan"
pip install -e "git+$CKAN_THEME_REPO_TAG#egg=$CKAN_THEME_NAME"
pip install -e "git+$DATAPUSHER_REPO_TAG#egg=datapusher"

# install dependencies
pip install -r "$VIRTUALENV_DIR/src/ckan/requirements.txt"
(cd  $VIRTUALENV_DIR/src/datapusher && pip install -r requirements.txt)

# make sure you’re using the virtualenv’s copies of commands like paster rather than any system-wide installed copies
deactivate
. "$VIRTUALENV_DIR/bin/activate"

. $INIT_DIR/setup_config.sh


mv /etc/solr/conf/schema.xml /etc/solr/conf/schema.xml.bak
ln -s $VIRTUALENV_DIR/src/ckan/ckan/config/solr/schema.xml /etc/solr/conf/schema.xml
replace_all "solr_url = $SOLR_URL" '/' '\/'
replace_ini_entry --file "$CONFIG_PATH" --search-raw "solr_url" --replacement-raw "$RET"


# export variables for template rendering engine  - mush (mustache-like)
export CKAN_CONFIG_DIR CKAN_INSTANCE_NAME CKAN_DOMAIN VIRTUALENV_DIR CKAN_CONFIG_FILENAME MAX_RESOURCE_SIZE_IN_MEGABYTES

chmod 644 "$CKAN_CONFIG_DIR/$CKAN_INSTANCE_NAME.wsgi"

deactivate
. "$VIRTUALENV_DIR/bin/activate"

# setting datastore permission as per instruction on CKAN guide
paster --plugin=ckan db upgrade -c "$CONFIG_PATH"
paster --plugin=ckan search-index rebuild -r -c "$CONFIG_PATH"

# make sure all folders have the correct owner
chown -R $OWNER_USER:$OWNER_GROUP $VIRTUALENV_DIR
chown -R $OWNER_USER:$OWNER_GROUP $UPLOADS_DIR

# apply changes
service apache2 restart
service jetty restart


# Disable maintenance mode if it was enabled
rm -fv $MAINTENANCE_CONFIG
ln -s "$OPENDATA_CONFIG" "$OPENDATA_CONFIG_LINK"
echo "Reloading Nginx to disable maintenance mode..."
service nginx restart
