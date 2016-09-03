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
replace_ini_entry --file "$CONFIG_PATH" --search-raw "ckan\.auth\.create_user_via_web =" --replacement-raw "ckan\.auth\.create_user_via_web = $CREATE_USER_VIA_WEB"

echo ""                                                           >> "$CONFIG_PATH"
echo "# http://docs.sqlalchemy.org/en/rel_0_9/core/pooling.html"  >> "$CONFIG_PATH"
echo "ckan.datastore.sqlalchemy.pool_size = 20"                   >> "$CONFIG_PATH"
echo "ckan.datastore.sqlalchemy.max_overflow = 30"                >> "$CONFIG_PATH"
