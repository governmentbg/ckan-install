#!/usr/bin/env bash

INIT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $INIT_DIR/../config.sh
source $INIT_DIR/../bash-utilities/utils.sh
source $INIT_DIR/../mush/mush.sh

# activate virtualenv
. "$VIRTUALENV_DIR/bin/activate"

# install ckan to virtualenv
pip install -e "git+$CKAN_REPO_TAG#egg=ckan"

# install dependencies
pip install -r "$VIRTUALENV_DIR/src/ckan/requirements.txt"

# make sure you’re using the virtualenv’s copies of commands like paster rather than any system-wide installed copies
deactivate
. "$VIRTUALENV_DIR/bin/activate"

# alias path to config
CONFIG_PATH="$CKAN_CONFIG_DIR/$CKAN_CONFIG_FILENAME"

## create config file
paster make-config ckan "$CONFIG_PATH"

# Repoze.who configuration file needs to be accessible in the same directory as your CKAN config file
ln -s "$VIRTUALENV_DIR/src/ckan/who.ini" "$CKAN_CONFIG_DIR/who.ini"

mv /etc/solr/conf/schema.xml /etc/solr/conf/schema.xml.bak
ln -s $VIRTUALENV_DIR/src/ckan/ckan/config/solr/schema.xml /etc/solr/conf/schema.xml

replace_all "solr_url = $SOLR_URL" '/' '\/'
replace_ini_entry --file "$CONFIG_PATH" --search-raw "solr_url" --replacement-raw "$RET"


# export variables for template rendering engine  - mush (mustache-like)
export CKAN_CONFIG_DIR CKAN_INSTANCE_NAME CKAN_DOMAIN VIRTUALENV_DIR CKAN_CONFIG_FILENAME MAX_RESOURCE_SIZE_IN_MEGABYTES

# setting datastore permission as per instruction on CKAN guide
paster --plugin=ckan datastore set-permissions -c "$CONFIG_PATH" | sudo -u postgres psql --set ON_ERROR_STOP=1
# database init
paster --plugin=ckan db upgrade -c "$CONFIG_PATH"

# make sure all folders have the correct owner
chown -R $OWNER_USER:$OWNER_GROUP $VIRTUALENV_DIR
chown -R $OWNER_USER:$OWNER_GROUP $UPLOADS_DIR

# apply changes
service apache2 restart
service nginx restart
service jetty restart
