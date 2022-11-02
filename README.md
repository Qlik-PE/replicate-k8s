# Using Qlik Replicate in a Kubernetes Environment

We have been asked on any number of occasions whether Qlik Replicate can be deployed
in a Kubernetes environment. The short answer is "yes". This repository contains 
the scripts and configuration YAML files needed to stand up a demonstration environment
for you to experiment with.

## Qlik Replicate and Docker

Qlik fully supports the deployment of Qlik Replicate in a Docker image. However, Qlik does not 
maintain a publicly accessible repository where you can download an image. You will
need to provide your own.

> Note: while Docker is fully supported by Qlik and Qlik Replicate can be deployed in
> a Kubernetes cluster, Kubernetes deployments are not formally supported by Qlik
> at the present time. Consequently, Qlik's support team will likely not be able to 
> assist with issues specific to the Kubernetes environment as they lack the necessary
> expertise.

An example *Dockerfile* and supporting scripts can be found in the `docker` subdirectory. You
very likely will want to customize this for the specific requirements of your organization, 
particularly with regard to the database drivers that you choose to install..
If you don't have one already, you will need to build a Qlik Replicate docker image to work with.

## Kubernetes Production Best Practices

* Create Kubernetes secrets to hold SSL certs, Replicate password, and your Replicate license file.
* The replication factor for your Replicate pod should be set to 1. Replicate does
not support sharing the data directory in active/active fashion across multiple instances
of Replicate.
* The Replicate "data directory" should be located on storage that can be shared with all
nodes in your cluster unless you are going to lock Replicate to a specific node. 

> The data directory is used heavily by Qlik Replicate. In high volume use cases
> performance can be impacted if access to this shared storage is suboptimal. 

