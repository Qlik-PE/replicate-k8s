#! /bin/bash

if [ ! -x "$(which gcloud)" ]
then
   echo "ERROR: gcloud not found in path"
   exit 1
fi

if [ ! -x "$(which kubectl)" ]
then
   echo "ERROR: kubectl not found in path"
   exit 1
fi

# bring in the configration variables
.  demo-env.rc

if [ -n "$gcp_project" ]
then
   if ! gcloud projects describe "$gcp_project" > /dev/null
   then
      echo "ERROR: specified project $gcp_project was not found or is not accessible"
      exit 1
   fi
   gcloud config set project "$gcp_project"
fi

# enable gcloud services for GKE
gcloud services enable container.googleapis.com --project $gcp_project

# create the demo cluster. This can take several minutes to finish.
echo "***"
echo "*** Creating the cluster. This will take some time."
echo "***"
if gcloud container clusters create "$cluster_name" \
                 --num-nodes=4   \
                 --zone="$compute_zone" 
then
   echo "***"
   echo "*** Cluster creation complete"
   echo "***"
else 
   echo "***"
   echo "*** ERROR: Cluster creation failed"
   echo "***"
   exit 1
fi

# get credentials and configure kubectl to use the cluster
echo "*** Fetching cluster credentials"
gcloud container clusters get-credentials "$cluster_name" --zone="$compute_zone"

# create a secret that contains the replicate license key
./license-secret.sh ./license.txt

# doc for GKE persistent volumes, etc.
# https://cloud.google.com/kubernetes-engine/docs/concepts/persistent-volumes
# https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/gce-pd-csi-driver

for i in postgres mysql replicate dbloadgen
do
   echo ""
   echo "*** loading $i"
   kubectl apply -f $i.yaml 
done

#kubectl get secrets
#kubectl get all
#kubectl get services

# https://cloud.google.com/kubernetes-engine/docs/how-to/exposing-apps
#echo ""
#echo "*** NodePort info for accessing the pods within the cluster"
for i in replhost dbloadgen postgresdb mysqldb
do
   read -r key1 name key2 clusterIP key3 port key4 port2 < <( \
      kubectl get service $i --output yaml  \
        | grep -E "name:|clusterIP:|nodePort:|targetPort:" \
        | sed -e ':a; N; $!ba; s/\n/ /g' -e's/-//g')
   
   echo "$key1 $name    $key2 $clusterIP    $key3 $port $key4  $port2" > /dev/null
   case "$name" in
      "replhost")
         gcloud compute firewall-rules create replhost --allow "tcp:$port" --no-user-output-enabled
         replPort=$port
         ;;
      "dbloadgen")
         gcloud compute firewall-rules create dbloadgen --allow "tcp:$port" --no-user-output-enabled
         loadgenPort=$port
         ;;
      "mysqldb")
         mysqlPort=$port
         mysqlIP=$clusterIP
         ;;
      "postgresdb")
         postgresPort=$port
         postgresIP=$clusterIP
         ;;
      *)
         ;;
   esac
done

echo ""
#echo "*** Node external IP addresses"
#kubectl get nodes --output wide  | tr -s " " | cut -d " " -f 7

ipAddress=$(kubectl get nodes --output wide | tr -s " " | cut -d " " -f 7 | sed -n '2p')

echo ""
echo "Replicate URL:  https://$ipAddress:$replPort/attunityreplicate"
echo "DbLoadgen URL:  http://$ipAddress:$loadgenPort"
echo "MySQL host address: $mysqlIP   port: $mysqlPort"
echo "Postgres host address: $postgresIP   port: $postgresPort"

echo ""

