#!/usr/bin/env bash
source ../config.sh
source ../bash-utilities/utils.sh
INIT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )


apt-get update
apt-get install python-dev postgresql libpq-dev python-pip python-virtualenv git-core solr-jetty openjdk-6-jdk apache2 libapache2-mod-wsgi libapache2-mod-rpaf nginx-full postfix


# setup directorie
mkdir -p $VIRTUALENV_DIR
chown $OWNER_USER:$OWNER_GROUP $VIRTUALENV_DIR
mkdir -p $CKAN_ETC_DIR/default
chown $OWNER_USER:$OWNER_GROUP $CKAN_ETC_DIR


# setup directories from homedir
#mkdir -p $CKAN_DIR_SYMLINK/lib
#ln -s $CKAN_DIR_SYMLINK/lib $CKAN_LIB_DIR
#mkdir -p $CKAN_DIR_SYMLINK/etc
#ln -s $CKAN_DIR_SYMLINK/etc $CKAN_ETC_DIR

# setup virtualenv
virtualenv --no-site-packages $VIRTUALENV_DIR

# activate virtualenv
. $VIRTUALENV_DIR/bin/activate

# install ckan and theme to virtualenv
pip install -e "git+$CKAN_REPO_TAG#egg=ckan"
pip install -e "git+$CKAN_THEME_REPO_TAG#egg=$CKAN_THEME_NAME"

# install dependencies
pip install -r $VIRTUALENV_DIR/src/ckan/requirements.txt

# restart virtualenv
deactivate
. $VIRTUALENV_DIR/bin/activate


## database init
su postgres postgres.sh

paster make-config ckan "$CKAN_ETC_DIR/default/development.ini"

replace_ini_entry --file "$CKAN_ETC_DIR/default/development.ini" --search-raw "sqlalchemy\.url =" --replacement-raw "sqlalchemy\.url = postgresql:\/\/$POSTGRES_NEW_USER:$POSTGRES_PASS@localhost\/$POSTGRES_DBNAME"
replace_ini_entry --file "$CKAN_ETC_DIR/default/development.ini" --search-raw "ckan\.site_id =" --replacement-raw "ckan\.site_id = $CKAN_INSTANCE_NICKNAME"
replace_ini_entry --file "$CKAN_ETC_DIR/default/development.ini" --search-raw "ckan\.plugins =" --replacement-raw "ckan\.plugins = stats text_view recline_view datastore datapusher obshtestvo_theme"

# solr & jetty
#mv /etc/solr/conf/schema.xml /etc/solr/conf/schema.xml.bak
#ln -s $VIRTUALENV_DIR/src/ckan/ckan/config/solr/schema.xml /etc/solr/conf/schema.xml
#replace_ini_entry --file "$CKAN_ETC_DIR/default/development.ini" --search-raw "solr_url" --replacement-raw "solr_url = $SOLR_URL"

paster --plugin=ckan db init -c "$CKAN_ETC_DIR/default/development.ini"

# setup datastore
replace_ini_entry --file "$CKAN_ETC_DIR/default/development.ini" --search-raw "ckan.datastore.write_url =" "ckan.datastore.write_url = postgresql:\/\/$POSTGRES_NEW_USER:$POSTGRES_PASS@localhost\/$POSTGRES_DATASTORE_DBNAME"
replace_ini_entry --file "$CKAN_ETC_DIR/default/development.ini" --search-raw "ckan.datastore.read_url =" "ckan.datastore.read_url = postgresql:\/\/$POSTGRES_NEW_USER:$POSTGRES_PASS@localhost\/$POSTGRES_DATASTORE_DBNAME"
paster --plugin=ckan datastore set-permissions -c "$CKAN_ETC_DIR/default/development.ini" | sudo -u postgres psql --set ON_ERROR_STOP=1

# Repoze.who configuration file needs to be accessible in the same directory as your CKAN config file
ln -s $VIRTUALENV_DIR/src/ckan $CKAN_ETC_DIR/default/who.ini

cp "$CKAN_ETC_DIR/default/development.ini" "$CKAN_ETC_DIR/default/production.ini"
cp "$INIT_DIR/../templates/apache.wsgi" ""
