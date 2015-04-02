#!/usr/bin/env bash
BATCH_USER_CREATE_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $BATCH_USER_CREATE_DIR/config.sh
source $BATCH_USER_CREATE_DIR/bash-utilities/utils.sh


# activate virtualenv
. "$VIRTUALENV_DIR/bin/activate"
# alias path to config
CONFIG_PATH="$CKAN_CONFIG_DIR/$CKAN_CONFIG_FILENAME"

# creates a user from a file line in the format: FirstName LastName;email@example.com
while read -r USER_ENTRY || [[ -n $USER_ENTRY ]]
do
  USER_FIELDS=()
  OIFS=$IFS
  IFS=';'
  arr2=$IN
  for FIELD in $USER_ENTRY
  do
    USER_FIELDS+=("$FIELD")
  done
  IFS=$OIF
  replace_all "${USER_FIELDS[1]%@*}" '.' '_'
  USER_FIELDS+=("$RET")
  USER_PASSWORD=$(pwgen -1 16)
  echo 'creating new user...'
  paster --plugin=ckan user add "${USER_FIELDS[2]}" email="${USER_FIELDS[1]}" fullname="${USER_FIELDS[0]}" password="$USER_PASSWORD" -c "$CONFIG_PATH"
  echo 'created:'
  echo "username: ${USER_FIELDS[2]}"
  echo "name: ${USER_FIELDS[0]}"
  echo "password: ${USER_PASSWORD}"
  echo '-----------'
done < $1