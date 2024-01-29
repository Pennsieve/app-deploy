#!/bin/sh

pennsieve agent
pennsieve whoami
pennsieve dataset use $1

echo "getting here 1"

ls -alh /mnt/efs/output/$2
timestamp=$(date +%Y%m%d_%H%M%S%Z)
target_path="${TARGET_PATH:-"output-$timestamp-$2"}"

echo "getting here 2"

pennsieve manifest create /mnt/efs/output/$2 -t $target_path

echo "getting here 3"

pennsieve manifest list 1
pennsieve upload manifest 1

echo "getting here 4"