#! /bin/bash

eval $(minikube docker-env) # lets minikube pull local images.

kubectl apply -f postgres.yaml
kubectl apply -f mysql.yaml
kubectl apply -f replicate.yaml
kubectl apply -f dbloadgen.yaml

kubectl get secrets
kubectl get all

minikube service list

