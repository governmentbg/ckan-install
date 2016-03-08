#!/bin/bash

INIT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $INIT_DIR/../config.sh
source $INIT_DIR/../bash-utilities/utils.sh
source $INIT_DIR/../mush/mush.sh

# activate virtualenv
. "$VIRTUALENV_DIR/bin/activate"

pip install polib
pip install -e "git+https://github.com/RadoRado/ckanext-extrafields#egg=ckanext-extrafields"

# replace_all "ckan\.plugins = stats text_view recline_view datastore datapusher $CKAN_THEME_NAME" '/' '\/'
# replace_ini_entry --file "$CONFIG_PATH" --search-raw "ckan\.plugins =" --replacement-raw "$RET"



