#!/bin/bash

set -e

. /root/ckan-install/config.sh

dt=`date +%Y%m%d`

dst=$BACKUP_DIR/$dt

mkdir -p $dst

cd $BACKUP_DIR

for i in $BACKUP_PGDBNAMES; do
	su postgres -c "pg_dump --blobs --format=c $i" > $dst/$i.pgsql.dump
done

for i in $BACKUP_PATHS; do
	oname=`echo $i | sed 's%/%_%g'`
	tar cf - $i 2>/dev/null | nice pbzip2 -c > $dst/$oname.tar.bz2
done

if [ ! -z "$BACKUP_DAYS_TO_KEEP" ]; then
	# Delete all backups older than $BACKUP_DAYS_TO_KEEP except
	# backups made on the 1st of each month.
	find $BACKUP_DIR -mindepth 1 -maxdepth 1 -type d -mtime +$BACKUP_DAYS_TO_KEEP | grep -v '01$' | xargs rm -rfv
fi

cd $BACKUP_DIR_TO_SYNC

rsync -av --delete-after * $BACKUP_REMOTE_SYNC_LOCATION
