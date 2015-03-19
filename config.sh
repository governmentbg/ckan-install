#!/usr/bin/env bash
VIRTUALENV_DIR=/usr/lib/ckan/default
CKAN_DIR_SYMLINK=/root/ckan
CKAN_LIB_DIR=/usr/lib/ckan
CKAN_ETC_DIR=/etc/ckan
CKAN_REPO_TAG=https://github.com/obshtestvo/data.obshtestvo.bg.git@data.obshtestvo.bg
POSTGRES_NEW_USER=ckan_default
POSTGRES_DBNAME=ckan_default
POSTGRES_DATASTORE_DBNAME=datastore_default
CKAN_THEME_NAME=obshtestvo_theme
CKAN_THEME_REPO_TAG=https://github.com/obshtestvo/data.obshtestvo.bg-theme.git@master
POSTGRES_PASS=secretpassword
OWNER_USER=www-data
OWNER_GROUP=www-data
CKAN_INSTANCE_NICKNAME=opendatabulgaria
SOLR_URL=http://127.0.0.1:8983/solr