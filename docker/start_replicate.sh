#!/bin/bash
# Expect four parameters:
#    1. Data folder
#    2. Admin password
#    3. Rest port
#    4. license file, or empty to indicate that no license needs to be imported.
# Create data folder and grant user attunity ownership of it

if [ -z $1 ] || [ -z $2 ] || [ -z $3 ]; then
  echo "Usage: start-replicate.sh <Data folder> <Admin password> <Rest port> [<license file>]"
  exit 1
fi

mkdir -p $1
chown attunity:attunity $1
# Change admin password
su attunity -c "/opt/attunity/replicate/bin/repctl.sh -d $1 setserverpassword $2" >> /dev/null 2>&1
if [ ! -z "$4" ]; then
su attunity -c "/opt/attunity/replicate/bin/repctl.sh -d $1 importlicense license_file=/$4" >> /dev/null 2>&1
fi
# Run Attunity Replicate
su attunity -c "/opt/attunity/replicate/bin/repctl.sh -d $1 service start rest_port=$3" >> /dev/null 2>&1
