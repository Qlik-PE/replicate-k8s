#! /bin/bash

# bring in the configration variables
.  demo-env.rc

gcloud config set project "$gcp_project"

gcloud compute firewall-rules delete replhost --quiet --no-user-output-enabled
gcloud compute firewall-rules delete dbloadgen --quiet --no-user-output-enabled

kubectl delete pod dbloadgen mysqldb postgresdb 

kubectl delete deployment replhost 

kubectl delete service dbloadgen mysqldb postgresdb replhost 

kubectl delete pvc repldata


gcloud container clusters delete $cluster_name --zone=$compute_zone --quiet


