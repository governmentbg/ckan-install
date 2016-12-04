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
	tar cf - $i 2>/dev/null | pbzip2 -c > $dst/$oname.tar.bz2
done

cd $BACKUP_DIR_TO_SYNC

rsync -a * $BACKUP_REMOTE_SYNC_LOCATION
