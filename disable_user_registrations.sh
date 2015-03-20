#!/usr/bin/env bash
source ../config.sh
source ../bash-utilities/utils.sh
DISABLE_REGISTARATION_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

replace_ini_entry --file "$CKAN_ETC_DIR/default/development.ini" --search-raw "ckan\.auth\.create_user_via_web =" --replacement-raw "ckan\.auth\.create_user_via_web = false"
