#! /bin/bash
#
# Create a secret containing the license key for Replicate.
# If the file is not in JSON format, it is assumed to be in
# the standard text format and will be converted to json.
#
repl_license=/tmp/license.json

if [ "$#" -ne "1" ]
then
   echo "Usage: license-secret.sh <license-file>"
   exit 1
fi

if [ ! -f "$1" ]
then
   echo "ERROR: invalid file specified: $1"
   exit 1
fi

if [[ "$1" == *".json" ]]
then
  cp "$1" $repl_license
else
   # convert the file to json format
   echo "*** converting license file to JSON format"
   perl -e '$comma = q(); for (<>) { next if /^\s*#/; if (/license_type=/) { $license=1; print qq({\n  "cmd.license":  {); } next unless $license and /=/; chomp; s/=/":"/; print qq(${comma}\n    "${_}"); $comma = q(,); } print qq(\n  }\n}\n);' < "$1" > $repl_license
fi

if kubectl get secrets | grep -q repl-license
then
  kubectl delete secret repl-license
fi

kubectl create secret generic repl-license --from-file=${repl_license} 

rm $repl_license

