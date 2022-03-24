#!/bin/bash

local_dir=$1
remote_dir=$2

[ -z "$local_dir" ] && { echo "var local_dir empty"; exit 1; }
[ -z "$remote_dir" ] && { echo "var remote_dir empty"; exit 2; }

#local_dir="/data2/backup_ceph_"
#remote_dir="cephbackup@ip:/mnt/nasopf/seapath/backups_ceph_cluster_proj/"

d=`date +%Y%m%d%H%M`
latest_full=`ls -d "$local_dir"* | tail -n 1`
[ ! -d "$latest_full" ] && { echo "latest full backup not found"; exit 3; }

rbd list | while read i
do
  echo $i
  latest=`rbd snap list rbd/$i | tail -n 1 | awk '{ print $2 }'`
  echo creating new snapshot
  rbd snap create rbd/$i@$d
  echo creating diff
  rbd export-diff --from-snap $latest rbd/$i@$d $latest_full/"$i"_"$latest"_"$d".diff
  echo backuping vm xml
  rbd image-meta get rbd/$i xml > $latest_full/$i-$d.xml
  echo backuping metadata
  rbd image-meta list rbd/$i > $latest_full/$i-meta-$d.txt
done
rsync -ave ssh --progress $latest_full $remote_dir
