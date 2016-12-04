#!/usr/bin/env bash

# A script for upgrading our custom CKAN theme

set -e

# Load the config and helpers
INIT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $INIT_DIR/../config.sh
source $INIT_DIR/../bash-utilities/utils.sh
source $INIT_DIR/../mush/mush.sh

echo 'Activating virtualenv...'
. "$VIRTUALENV_DIR/bin/activate"

echo 'Removing the current version of the theme...'
pip uninstall -y ckanext-bulgarian-theme
rm -rfv "$VIRTUALENV_DIR/src/bulgarian-theme"

echo 'Reloading the virtualenv...'
deactivate
. "$VIRTUALENV_DIR/bin/activate"

echo 'Installing the new version of the theme...'
pip install -e "git+$CKAN_THEME_REPO_TAG#egg=$CKAN_THEME_NAME"

echo 'Fixing file and folder permissions...'
chown -R $OWNER_USER:$OWNER_GROUP $VIRTUALENV_DIR

echo 'Theme updated, restart the webserver if needed:'
echo 'service apache2 restart'
