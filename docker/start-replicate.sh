#! /bin/bash

attunitybin=/opt/attunity/replicate/bin
datadir=/data
ssldir=${datadir}/ssl/data
repllicense=/repl-license/license.json


# look for this directory. If it exists, then copy the contents into 
# the Replicate data directory. Otherwise, we'll let replicate
# generate self-signed certificates.
if [ -d /sslcerts ]
then
  mkdir -p $ssldir
  cp /sslcerts/* $ssldir
  chown -R attunity:attunity $datadir
fi


if [ -d $attunitybin ]
then
   cd $attunitybin 

   # look for this directory. If it exists, then apply the license
   # to this instance of Replicate.
   if [ -f $repllicense ]
   then
      # install the license
      ./repctl -d $datadir importlicense license_file=$repllicense
   fi

   # set the password if it is passed in via an environment variable. 
   # Otherwise, default to "admin"
   PW=${PASSWORD:-AttunityAdmin123}
   ./repctl -d ${datadir} SETSERVERPASSWORD "${PW}"

   ./areplicate start
else
   echo "ERROR: $attunitybin directory not found"
fi
