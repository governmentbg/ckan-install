#!/usr/bin/env bash
INIT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $INIT_DIR/../config.sh
source $INIT_DIR/../bash-utilities/utils.sh


apt-get update

input_two_choice "When postfix asks for config you should choose 'Internet Site'?" ok quit
if [ "$RET" == "quit" ]
then
  exit 1
fi
input_two_choice "When postfix asks for 'mail name' you should choose smth like 'opendata.government.bg'?" ok quit
if [ "$RET" == "quit" ]
then
  exit 1
fi
apt-get install python-dev postgresql libpq-dev python-pip python-virtualenv \
solr-jetty openjdk-6-jdk apache2 libapache2-mod-wsgi libapache2-mod-rpaf nginx-full postfix \
build-essential libxslt1-dev libxml2-dev git

## setup directories
## dependencies dir
mkdir -p "$VIRTUALENV_DIR"
chown $OWNER_USER:$OWNER_GROUP "$VIRTUALENV_DIR"
## configuration dir
mkdir -p "$CKAN_ETC_DIR/default"
chown $OWNER_USER:$OWNER_GROUP -R "$CKAN_ETC_DIR"
## upload files dir
mkdir -p "$UPLOADS_DIR"
chown $OWNER_USER:$OWNER_GROUP "$UPLOADS_DIR"
chmod u+rwx "$UPLOADS_DIR"

# setup directories from homedir - SKIP UNTIL THIS SETUP SCRIPT IS FINISHED
#mkdir -p $CKAN_DIR_SYMLINK/lib
#ln -s $CKAN_DIR_SYMLINK/lib $CKAN_LIB_DIR
#mkdir -p $CKAN_DIR_SYMLINK/etc
#ln -s $CKAN_DIR_SYMLINK/etc $CKAN_ETC_DIR

# setup virtualenv
virtualenv --no-site-packages "$VIRTUALENV_DIR"

# activate virtualenv
. "$VIRTUALENV_DIR/bin/activate"

# install ckan, data.government.bg theme, and datapusher to virtualenv
pip install -e "git+$CKAN_REPO_TAG#egg=ckan"
pip install -e "git+$CKAN_THEME_REPO_TAG#egg=$CKAN_THEME_NAME"
pip install -e "git+$DATAPUSHER_REPO_TAG#egg=datapusher"

# install dependencies
pip install -r "$VIRTUALENV_DIR/src/ckan/requirements.txt"
(cd  $VIRTUALENV_DIR/default/src/datapusher && pip install -r requirements.txt)

# make sure you’re using the virtualenv’s copies of commands like paster rather than any system-wide installed copies
deactivate
. "$VIRTUALENV_DIR/bin/activate"


## database init
su postgres postgres.sh

## create config file
paster make-config ckan "$CKAN_ETC_DIR/default/development.ini"

## first and upmost changes: db connectivity, file storage, site name, and loaded funcitonality
## (replace forward slash for every setting because of SED)
## (manually escape dot character for regular expressions)
replace_all "sqlalchemy\.url = postgresql://$POSTGRES_NEW_USER:$POSTGRES_PASS@localhost/$POSTGRES_DBNAME" '/' '\/'
replace_ini_entry --file "$CKAN_ETC_DIR/default/development.ini" --search-raw "sqlalchemy\.url =" --replacement-raw "$RET"
replace_all "ckan\.site_id = $CKAN_INSTANCE_NICKNAME" '/' '\/'
replace_ini_entry --file "$CKAN_ETC_DIR/default/development.ini" --search-raw "ckan\.site_id =" --replacement-raw "$RET"
replace_all "ckan\.plugins = stats text_view recline_view datastore datapusher obshtestvo_theme" '/' '\/'
replace_ini_entry --file "$CKAN_ETC_DIR/default/development.ini" --search-raw "ckan\.plugins =" --replacement-raw "$RET"
replace_all "ckan\.storage_path = $UPLOADS_DIR" '/' '\/'
replace_ini_entry --file "$CKAN_ETC_DIR/default/development.ini" --search-raw "ckan\.storage_path =" --replacement-raw "$RET"
replace_all "ckan.datastore.write_url = postgresql://$POSTGRES_NEW_USER:$POSTGRES_PASS@localhost/$POSTGRES_DATASTORE_DBNAME" '/' '\/'
replace_ini_entry --file "$CKAN_ETC_DIR/default/development.ini" --search-raw "ckan\.datastore.write_url =" --replacement-raw "$RET"
replace_all "ckan.datastore.read_url = postgresql://$POSTGRES_NEW_READONLY_USER:$POSTGRES_PASS@localhost/$POSTGRES_DATASTORE_DBNAME" '/' '\/'
replace_ini_entry --file "$CKAN_ETC_DIR/default/development.ini" --search-raw "ckan\.datastore.read_url =" --replacement-raw "$RET"
replace_all "ckan\.site_url = $CKAN_URL" '/' '\/'
replace_ini_entry --file "$CKAN_ETC_DIR/default/development.ini" --search-raw "ckan\.site_url =" --replacement-raw "$RET"
replace_all "ckan\.datapusher\.url = $DATAPUSHER_URL" '/' '\/'
replace_ini_entry --file "$CKAN_ETC_DIR/default/development.ini" --search-raw "ckan\.datapusher\.url =" --replacement-raw "$RET"

# setting datastore permission as per instruction on CKAN guide
paster --plugin=ckan datastore set-permissions -c "$CKAN_ETC_DIR/default/development.ini" | sudo -u postgres psql --set ON_ERROR_STOP=1

cp "$VIRTUALENV_DIR/default/src/datapusher/deployment/datapusher.conf" /etc/apache2/sites-available/
cp "$VIRTUALENV_DIR/default/src/datapusher/deployment/datapusher.wsgi" "$CKAN_ETC_DIR"
cp "$VIRTUALENV_DIR/default/src/datapusher/deployment/datapusher_settings.py" "$CKAN_ETC_DIR"
# @todo edit datapusher.wsgi and datapusher.conf
echo "NameVirtualHost *:8800" >> /etc/apache2/ports.conf
echo "Listen 8800" >> /etc/apache2/ports.conf
a2ensite datapusher
service apache2 restart


# solr & jetty - AWAITING INSTRUCTIONS
#mv /etc/solr/conf/schema.xml /etc/solr/conf/schema.xml.bak
#ln -s $VIRTUALENV_DIR/src/ckan/ckan/config/solr/schema.xml /etc/solr/conf/schema.xml
#replace_ini_entry --file "$CKAN_ETC_DIR/default/development.ini" --search-raw "solr_url" --replacement-raw "solr_url = $SOLR_URL"

paster --plugin=ckan db init -c "$CKAN_ETC_DIR/default/development.ini"

# Repoze.who configuration file needs to be accessible in the same directory as your CKAN config file
ln -s "$VIRTUALENV_DIR/src/ckan" "$CKAN_ETC_DIR/default/who.ini"

cp "$CKAN_ETC_DIR/default/development.ini" "$CKAN_ETC_DIR/default/production.ini"
cp "$INIT_DIR/../templates/apache.wsgi" ""


service apache2 reload