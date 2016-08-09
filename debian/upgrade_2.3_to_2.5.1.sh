#!/usr/bin/env bash
INIT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $INIT_DIR/../config.sh
source $INIT_DIR/../bash-utilities/utils.sh
source $INIT_DIR/../mush/mush.sh


service apache2 stop
service nginx stop

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

deactivate
. "$VIRTUALENV_DIR/bin/activate"
pip install --upgrade setuptools
pip install --upgrade pip
deactivate
. "$VIRTUALENV_DIR/bin/activate"

# install ckan, data.government.bg theme, and datapusher to virtualenv
pip install -e "git+$CKAN_REPO_TAG#egg=ckan"

# install dependencies
# pip install -r "$VIRTUALENV_DIR/src/ckan/requirements.txt"
pip install -r "$VIRTUALENV_DIR/src/ckan/requirements.txt"
pip install --upgrade -r "$VIRTUALENV_DIR/src/ckan/requirements.txt"

pip uninstall html5lib
pip install html5lib==0.9999999

# make sure you’re using the virtualenv’s copies of commands like paster rather than any system-wide installed copies
deactivate
. "$VIRTUALENV_DIR/bin/activate"

# alias path to config
CONFIG_PATH="$CKAN_CONFIG_DIR/$CKAN_CONFIG_FILENAME"

## create config file
paster make-config ckan "$CONFIG_PATH"

## first and upmost changes: db connectivity, file storage, site name, and loaded funcitonality
## (replacing forward slash for every setting because of SED)
## (manually escaping dot character for regular expressions)
replace_all "sqlalchemy\.url = postgresql://$POSTGRES_NEW_USER:$POSTGRES_PASS@localhost/$POSTGRES_DBNAME" '/' '\/'
replace_ini_entry --file "$CONFIG_PATH" --search-raw "sqlalchemy\.url =" --replacement-raw "$RET"
replace_all "ckan\.site_id = $CKAN_INSTANCE_NAME" '/' '\/'
replace_ini_entry --file "$CONFIG_PATH" --search-raw "ckan\.site_id =" --replacement-raw "$RET"
replace_all "ckan\.plugins = stats text_view recline_view datastore datapusher $CKAN_THEME_NAME" '/' '\/'
replace_ini_entry --file "$CONFIG_PATH" --search-raw "ckan\.plugins =" --replacement-raw "$RET"
replace_all "ckan\.storage_path = $UPLOADS_DIR" '/' '\/'
replace_ini_entry --file "$CONFIG_PATH" --search-raw "ckan\.storage_path =" --replacement-raw "$RET"
replace_all "ckan.datastore.write_url = postgresql://$POSTGRES_NEW_USER:$POSTGRES_PASS@localhost/$POSTGRES_DATASTORE_DBNAME" '/' '\/'
replace_ini_entry --file "$CONFIG_PATH" --search-raw "ckan\.datastore.write_url =" --replacement-raw "$RET"
replace_all "ckan.datastore.read_url = postgresql://$POSTGRES_NEW_READONLY_USER:$POSTGRES_PASS@localhost/$POSTGRES_DATASTORE_DBNAME" '/' '\/'
replace_ini_entry --file "$CONFIG_PATH" --search-raw "ckan\.datastore.read_url =" --replacement-raw "$RET"
replace_all "ckan\.site_url = $CKAN_URL" '/' '\/'
replace_ini_entry --file "$CONFIG_PATH" --search-raw "ckan\.site_url =" --replacement-raw "$RET"
replace_all "ckan\.datapusher\.url = $DATAPUSHER_URL" '/' '\/'
replace_ini_entry --file "$CONFIG_PATH" --search-raw "ckan\.datapusher\.url =" --replacement-raw "$RET"
replace_ini_entry --file "$CONFIG_PATH" --search-raw "ckan\.locale_default = " --replacement-raw "ckan\.locale_default = $LOCALE"
replace_ini_entry --file "$CONFIG_PATH" --search-raw "ckan\.locale_order = " --replacement-raw "ckan\.locale_order = $LOCALES_ORDER"
replace_all "ckan\.favicon = $FAVICON_RELATIVE_URL" '/' '\/'
replace_ini_entry --file "$CONFIG_PATH" --search-raw "ckan\.favicon =" --replacement-raw "$RET"
replace_all "ckan\.site_title = $CKAN_TITLE" '/' '\/'
replace_ini_entry --file "$CONFIG_PATH" --search-raw "ckan\.site_title =" --replacement-raw "$RET"
replace_ini_entry --file "$CONFIG_PATH" --search-raw "email_to =" --replacement-raw "email_to = $EMAIL_TO"
replace_ini_entry --file "$CONFIG_PATH" --search-raw "error_email_from =" --replacement-raw "error_email_from = $ERROR_EMAIL_FROM"
replace_ini_entry --file "$CONFIG_PATH" --search-raw "smtp\.server =" --replacement-raw "smtp\.server = $SMTP_HOST"
replace_ini_entry --file "$CONFIG_PATH" --search-raw "smtp\.starttls =" --replacement-raw "smtp\.starttls = $SMTP_TLS"
replace_ini_entry --file "$CONFIG_PATH" --search-raw "smtp\.user =" --replacement-raw "smtp\.user = $SMTP_USER"
replace_ini_entry --file "$CONFIG_PATH" --search-raw "smtp\.password =" --replacement-raw "smtp\.password = $SMTP_PASS"
replace_ini_entry --file "$CONFIG_PATH" --search-raw "smtp\.mail_from =" --replacement-raw "smtp\.mail_from = $SMTP_MAIL_FROM"
replace_ini_entry --file "$CONFIG_PATH" --search-raw "ckan\.max_resource_size =" --replacement-raw "ckan\.max_resource_size = $MAX_RESOURCE_SIZE_IN_MEGABYTES"

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
service nginx restart
service jetty restart
