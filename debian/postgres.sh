#!/usr/bin/env bash
source ../config.sh
source ../bash-utilities/utils.sh

psql -l
input_two_choice "Are all databases UTF8? encoded" y n
if [ "$RET" == "n" ]
then
echo "ERROR: internationalisation may be a problem"
input_two_choice "Do you want to proceed anyway?" y n
  if [ "$RET" == "n" ]
  then
  exit 1
  fi
fi

echo 'creating write user...'
createuser -S -D -R -P $POSTGRES_NEW_USER
echo 'creating readonlyuser user...'
createuser -S -D -R -P $POSTGRES_NEW_READONLY_USER
createdb -O $POSTGRES_NEW_USER $POSTGRES_DBNAME -E utf-8
createdb -O $POSTGRES_NEW_USER $POSTGRES_DATASTORE_DBNAME -E utf-8