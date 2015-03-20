#!/usr/bin/env bash
DISABLE_REGISTARATION_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DISABLE_REGISTARATION_DIR/config.sh
source $DISABLE_REGISTARATION_DIR/bash-utilities/utils.sh

replace_ini_entry --file "$CKAN_CONFIG_DIR/$CKAN_CONFIG_FILENAME" --search-raw "ckan\.auth\.create_user_via_web =" --replacement-raw "ckan\.auth\.create_user_via_web = false"
