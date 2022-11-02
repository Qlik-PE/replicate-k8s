#! /bin/bash
#
image=replicate

if [ "$#" -ne "1" ]
then
   echo "Usage: docker_build.sh <replicate_file.rpm>"
   exit 1
fi

docker build --no-cache --file Dockerfile --build-arg installfile="$1" -t $image:k8s .

