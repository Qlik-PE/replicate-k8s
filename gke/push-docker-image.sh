#! /bin/bash

. demo-env.rc

gcloud services enable containerregistry.googleapis.com --project $gcp_project

# you may need to give docker access to your gcloud creds
# gcloud auth configure-docker gcr.io

docker tag replicate:k8s gcr.io/$gcp_project/replicate:k8s
docker push gcr.io/$gcp_project/replicate:k8s
