#!/usr/bin/env bash
CKAN_INSTANCE_NICKNAME=opendatabulgaria
CKAN_URL=http://opendata.government.bg
CKAN_THEME_NAME=obshtestvo_theme
CKAN_THEME_REPO_TAG=https://github.com/obshtestvo/data.obshtestvo.bg-theme.git@master
VIRTUALENV_DIR=/usr/lib/ckan/default
# Not implemented. Should we have separate venv for datapusher at all?
#VIRTUALENV_DATAPUSHER_DIR=/usr/lib/ckan/default
CKAN_DIR_SYMLINK=/root/ckan
CKAN_LIB_DIR=/usr/lib/ckan
CKAN_ETC_DIR=/etc/ckan
CKAN_REPO_TAG=https://github.com/obshtestvo/data.obshtestvo.bg.git@data.obshtestvo.bg
POSTGRES_NEW_USER=ckan_default
POSTGRES_NEW_READONLY_USER=datastore_default
POSTGRES_PASS=secretpassword
POSTGRES_DBNAME=ckan_default
POSTGRES_DATASTORE_DBNAME=datastore_default
OWNER_USER=www-data
OWNER_GROUP=www-data
SOLR_URL=http://127.0.0.1:8983/solr
UPLOADS_DIR=/var/lib/ckan/default
DATAPUSHER_REPO_TAG=https://github.com/ckan/datapusher.git@master
DATAPUSHER_URL=http://0.0.0.0:8800/