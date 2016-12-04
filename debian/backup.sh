#!/bin/bash

set -e

. /root/ckan-install/config.sh

dt=`date +%Y%m%d`

dst=$BACKUP_DIR/$dt

mkdir -p $dst

cd $BACKUP_DIR

for i in $BACKUP_PGDBNAMES; do
	echo "Backing up PostgreSQL database $i"
	su postgres -c "pg_dump --blobs --format=c $i" > $dst/$i.pgsql.dump
done

for i in $BACKUP_PATHS; do
	echo "Backing up path $i"
	oname=`echo $i | sed 's%/%_%g'`
	tar cf - $i 2>/dev/null | nice pbzip2 -c > $dst/$oname.tar.bz2
done

if [ ! -z "$BACKUP_DAYS_TO_KEEP" ]; then
	echo "Deleting backups older than $BACKUP_DAYS_TO_KEEP days (except backups made on the 1st of each month)..."
	find $BACKUP_DIR -mindepth 1 -maxdepth 1 -type d -mtime +$BACKUP_DAYS_TO_KEEP | grep -v '01$' | xargs rm -rfv
fi

echo "Syncing all backups to $BACKUP_REMOTE_SYNC_LOCATION"

cd $BACKUP_DIR_TO_SYNC

rsync -av --delete-after * $BACKUP_REMOTE_SYNC_LOCATION
