# Qlik Replicate Google Kubernetes Engine (GKE) Demo

The files in this directory contain all you will need to stand up a fully functional
Qlik Replicate demo in a *GKE* environment.

## Required Software

To run the demo, you will need to have 2 bits of software installed:

* The [gcloud](https://cloud.google.com/sdk/docs/install) CLI, which is needed to
interact with GKE, create and delete clusters, etc. 
> Note: You will need a GCP project to work in, and GKE-related APIs will need to be enabled
> in that project.
* The [kubectl](https://kubernetes.io/docs/reference/kubectl/kubectl/) 
CLI. *Kubectl* interacts with the Kubernetes cluster manager to deploy and manage pods, etc.

## Running the Demo

Follow these steps to run the demo.

### Enable Required GCP Services

```
gcloud services enable container.googleapis.com
```

### Set Environment Variables 

There is a local script, *demo-env.rc* where you should costomize the 
environment variables. This script is sourced by other scripts in
this directory when they execute.

```bash
#
# environment variables for run-demo.sh and cleanup-demo.sh
#

gcp_project=replicate-gke-demo
compute_zone=us-central1-a
cluster_name=repldemo-cluster

export USE_GKE_GCLOUD_AUTH_PLUGIN=True

```

### Push Replicate to a Docker Repository

If you haven't already, push your Replicate docker image to a Docker
repository that is accessible from GKE. If you don't have one, you can 
push one to a repository that is associated with your project in GCP.


```bash
#! /bin/bash

. demo-env.rc

gcloud services enable containerregistry.googleapis.com --project $gcp_project

# you may need to give docker access to your gcloud creds
# gcloud auth configure-docker gcr.io

docker tag replicate:k8s gcr.io/$gcp_project/replicate:k8s
docker push gcr.io/$gcp_project/replicate:k8s

```

### Run the Demo

The script *run-demo.sh* performs all of the steps needed to get your
cluster up and running in GKE. 

As with the MiniKube demo, you need to place a license file in this directory.
*run-demo.sh* will call *license-secret.sh* to create a secret containing the
Replicate license.

```text
[jneal@centosnuc gke]$ 
[jneal@centosnuc gke]$ ./run-demo.sh 
Updated property [core/project].
***
*** Creating the cluster. This will take some time.
***
Default change: VPC-native is the default mode during cluster creation for versions greater than 1.21.0-gke.1500. To create advanced routes based clusters, please pass the `--no-enable-ip-alias` flag
Default change: During creation of nodepools or autoscaling configuration changes for cluster versions greater than 1.24.1-gke.800 a default location policy is applied. For Spot and PVM it defaults to ANY, and for all other VM kinds a BALANCED policy is used. To change the default values use the `--location-policy` flag.
Note: Your Pod address range (`--cluster-ipv4-cidr`) can accommodate at most 1008 node(s).
Creating cluster repldemo-cluster in us-central1-a... Cluster is being health-checked (master is healthy
)...done.                                                                                               
Created [https://container.googleapis.com/v1/projects/replicate-gke-demo/zones/us-central1-a/clusters/repldemo-cluster].
To inspect the contents of your cluster, go to: https://console.cloud.google.com/kubernetes/workload_/gcloud/us-central1-a/repldemo-cluster?project=replicate-gke-demo
kubeconfig entry generated for repldemo-cluster.
NAME              LOCATION       MASTER_VERSION   MASTER_IP     MACHINE_TYPE  NODE_VERSION     NUM_NODES  STATUS
repldemo-cluster  us-central1-a  1.23.8-gke.1900  34.172.59.29  e2-medium     1.23.8-gke.1900  3          RUNNING
***
*** Cluster creation complete
***
*** Fetching cluster credentials
Fetching cluster endpoint and auth data.
kubeconfig entry generated for repldemo-cluster.
*** converting license file to JSON format
secret/repl-license created

*** loading postgres
configmap/postgres-env created
pod/postgresdb created
service/postgresdb created

*** loading mysql
configmap/mysql-env created
pod/mysqldb created
service/mysqldb created

*** loading replicate
configmap/replicate-env created
persistentvolumeclaim/repldata created
deployment.apps/replhost created
service/replhost created

*** loading dbloadgen
configmap/dbloadgen-env created
pod/dbloadgen created
service/dbloadgen created


Replicate URL:  https://35.192.114.224:30873/attunityreplicate
DbLoadgen URL:  http://35.192.114.224:30151
MySQL host address: 10.100.14.66   port: 3306
Postgres host address: 10.100.12.19   port: 5432

[jneal@centosnuc gke]$ 

```

The environment created is very similar to the MiniKube demo:

* MySQL
* PostgreSQL
* Qlik Replicate
* and Dbloadgen. [Dbloadgen](https://github.com/Qlik-PE/DbLoadgen) is an 
open source utility for generating test loads against 
a database, especially useful in cases like this where you want to test CDC. 

The primary difference in this environment is with Qlik Replicate. 
The *replicate.yaml* file creates a Kuberntes *deployment* with
a replication factor of 1, and creates 
a persistent volume for Qlik Replicate to use for the *data* directory.

The output at the end of the script's execution will provide you with the
IP addresses and ports you will use to access the resources in each pod.
We will assume at this point that you are somewhat comfortable with
Qlik Replicate. If you need some guidance, you can follow the steps in 
the MiniKube demo.

### Cleanup the Demo

When you are done testing, you can execute the *cleanup-demo.sh* script.

```text
[jneal@centosnuc gke]$ 
[jneal@centosnuc gke]$ ./cleanup-demo.sh 
Updated property [core/project].
pod "dbloadgen" deleted
pod "mysqldb" deleted
pod "postgresdb" deleted
deployment.apps "replhost" deleted
service "dbloadgen" deleted
service "mysqldb" deleted
service "postgresdb" deleted
service "replhost" deleted
persistentvolumeclaim "repldata" deleted
Deleting cluster repldemo-cluster...done.                                                               
Deleted [https://container.googleapis.com/v1/projects/replicate-gke-demo/zones/us-central1-a/clusters/repldemo-cluster].
[jneal@centosnuc gke]$ 

```

