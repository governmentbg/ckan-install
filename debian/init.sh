#!/usr/bin/env bash
INIT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $INIT_DIR/../config.sh
source $INIT_DIR/../bash-utilities/utils.sh
source $INIT_DIR/../mush/mush.sh


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
mkdir -p "$CKAN_CONFIG_DIR"
chown $OWNER_USER:$OWNER_GROUP -R "$CKAN_CONFIG_DIR"
## upload files dir
mkdir -p "$UPLOADS_DIR"
chown $OWNER_USER:$OWNER_GROUP "$UPLOADS_DIR"
chmod u+rwx "$UPLOADS_DIR"

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
replace_all "ckan\.plugins = stats text_view recline_view datastore datapusher obshtestvo_theme" '/' '\/'
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

# Repoze.who configuration file needs to be accessible in the same directory as your CKAN config file
ln -s "$VIRTUALENV_DIR/src/ckan/who.ini" "$CKAN_CONFIG_DIR/who.ini"


# SOLR setup
if [ "$SOLR_SETUP" == "auto" ]
then
  replace_ini_entry --file /etc/default/jetty --search-raw "NO_START=" --replacement-raw "NO_START=0"
  replace_ini_entry --file /etc/default/jetty --search-raw "JETTY_HOST=" --replacement-raw "JETTY_HOST=127\.0\.0\.1"
  replace_ini_entry --file /etc/default/jetty --search-raw "JETTY_PORT=" --replacement-raw "JETTY_PORT=$SOLR_PORT"
  # bug on debian
  rm /var/lib/jetty/webapps/solr
  ln -s /usr/share/solr/web/ /var/lib/jetty/webapps/solr
  echo "testing jetty"
  service jetty restart
  curl http://localhost:8983/solr/
  input_two_choice "Does the output of the previous command looks ok?" y n
  if [ "$RET" == "n" ]
  then
  echo "ERROR: Probably the JAVA_HOME setting in /etc/default/jetty is not set properly."
  ehco "Or a symlink in /var/lib/jetty/webapps is broken"
  echo "Please open another terminal and fix this."
  echo "Currently the installation script doesn't support resuming."
  input_two_choice "Have you completed the instruction  above?" y n
    if [ "$RET" == "n" ]
    then
    echo "WARNING: You have to manually run the code after SOLR_SETUP section in init.sh file"
    exit 1
    fi
  fi
fi
mv /etc/solr/conf/schema.xml /etc/solr/conf/schema.xml.bak
ln -s $VIRTUALENV_DIR/src/ckan/ckan/config/solr/schema.xml /etc/solr/conf/schema.xml
replace_all "solr_url = $SOLR_URL" '/' '\/'
replace_ini_entry --file "$CONFIG_PATH" --search-raw "solr_url" --replacement-raw "$RET"


# export variables for template rendering engine  - mush (mustache-like)
export CKAN_CONFIG_DIR CKAN_INSTANCE_NAME CKAN_DOMAIN VIRTUALENV_DIR CKAN_CONFIG_FILENAME

# apache ckan config
a2dissite default
replace_file_line_containing /etc/apache2/ports.conf "NameVirtualHost \*:80" "NameVirtualHost \*:8080"  && overwrite_save_file "/etc/apache2/ports.conf" "$RET"
replace_file_line_containing /etc/apache2/ports.conf "Listen 80" "Listen 8080" && overwrite_save_file "/etc/apache2/ports.conf" "$RET"
cat "$INIT_DIR/../templates/apache_ckan.conf" | mush > "/etc/apache2/sites-available/$CKAN_INSTANCE_NAME"
cat "$INIT_DIR/../templates/apache_ckan.wsgi" | mush > "$CKAN_CONFIG_DIR/$CKAN_INSTANCE_NAME.wsgi"
chmod 644 "$CKAN_CONFIG_DIR/$CKAN_INSTANCE_NAME.wsgi"
chown $OWNER_USER:$OWNER_GROUP "$CKAN_CONFIG_DIR/$CKAN_INSTANCE_NAME.wsgi"
a2ensite "$CKAN_INSTANCE_NAME"

# nginx ckan config
cp "$INIT_DIR/../templates/nginx-ckan.conf" "/etc/nginx/sites-available/$CKAN_INSTANCE_NAME"
ln -s "/etc/nginx/sites-available/$CKAN_INSTANCE_NAME" "/etc/nginx/sites-enabled/$CKAN_INSTANCE_NAME"

# apache datapusher config
echo "NameVirtualHost *:8800" >> /etc/apache2/ports.conf
echo "Listen 8800" >> /etc/apache2/ports.conf
cat "$INIT_DIR/../templates/apache_ckan_datapusher.conf" | mush > "/etc/apache2/sites-available/${CKAN_INSTANCE_NAME}_datapusher"
cat "$INIT_DIR/../templates/apache_ckan_datapusher.wsgi" | mush >  "$CKAN_CONFIG_DIR/${CKAN_INSTANCE_NAME}_datapusher.wsgi"
cp "$VIRTUALENV_DIR/src/datapusher/deployment/datapusher_settings.py" "$CKAN_CONFIG_DIR/${CKAN_INSTANCE_NAME}_datapusher_settings.py"
DATAPUSHER_CONFIG_PATH="$CKAN_CONFIG_DIR/${CKAN_INSTANCE_NAME}_datapusher_settings.py" # shortcut
replace_ini_entry --file "$DATAPUSHER_CONFIG_PATH" --search-raw "NAME =" --replacement-raw "NAME = '${CKAN_INSTANCE_NAME}_datapusher'"
replace_ini_entry --file "$DATAPUSHER_CONFIG_PATH" --search-raw "FROM_EMAIL =" --replacement-raw "FROM_EMAIL = '$SMTP_MAIL_FROM'"
replace_ini_entry --file "$DATAPUSHER_CONFIG_PATH" --search-raw "ADMINS =" --replacement-raw "ADMINS = ['$EMAIL_TO']"
chmod 644 "$CKAN_CONFIG_DIR/${CKAN_INSTANCE_NAME}_datapusher.wsgi"
chown $OWNER_USER:$OWNER_GROUP "$CKAN_CONFIG_DIR/${CKAN_INSTANCE_NAME}_datapusher.wsgi"
a2ensite "${CKAN_INSTANCE_NAME}_datapusher"

# setting datastore permission as per instruction on CKAN guide
paster --plugin=ckan datastore set-permissions -c "$CONFIG_PATH" | sudo -u postgres psql --set ON_ERROR_STOP=1
# database init
paster --plugin=ckan db init -c "$CONFIG_PATH"

# apply changes
service apache2 restart
service nginx restart