#!/bin/sh

pennsieve agent
pennsieve whoami
pennsieve dataset use $1

ls -alh /mnt/efs/output/$2
timestamp=$(date +%Y%m%d_%H%M%S%Z)
pennsieve manifest create /mnt/efs/output/$2 -t "output-$timestamp-$2"
pennsieve manifest list 1
pennsieve upload manifest 1
cat "/root/.pennsieve/agent.log"