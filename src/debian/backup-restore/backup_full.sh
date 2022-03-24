#!/bin/bash

local_dir=$1
remote_dir=$2

[ -z "$local_dir" ] && { echo "var local_dir empty"; exit 1; }
[ -z "$remote_dir" ] && { echo "var remote_dir empty"; exit 2; }

echo Removing old full backups local dirs
echo rm -rf "$local_dir"*, press enter to proceed
read
rm -rf "$local_dir"*

d=`date +%Y%m%d%H%M`
f="$local_dir""$d"
mkdir -p $f
rbd list | while read i
do
  echo $i
  echo sparsifying
  rbd sparsify $i
  echo purging snapshots
  rbd snap purge rbd/$i
  echo creating base snapshot
  rbd snap create rbd/$i@$d
  echo backuping vm xml
  rbd image-meta get rbd/$i xml > $f/$i-$d.xml
  echo backuping metadata
  rbd image-meta list rbd/$i > $f/$i-meta-$d.txt
  echo backuping snapshot
  qemu-img convert -f raw -O qcow2 rbd:rbd/$i@$d $f/$i"_"$d.qcow2
  echo ----
done
rsync -ave ssh --progress $f $remote_dir
