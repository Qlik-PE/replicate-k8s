# Building a Docker Image for Qlik Replicate

The files in this directory show an approach to building a docker image for
Qlik Replicate. 

> Another approach can be found as a download bundle in
> the Qlik Data Integration download area. The file name will be something like: 
> *areplicate-2022.5.0-499_docker_file_generator.tar.gz*.

In order to build a docker image, you will need to download the Linux install bundle for Qlik
Replicate and extract it. For example:

```
[docker]$ tar xzvf areplicate-2022.5.0-499.x86_64.tar.gz 
areplicate-2022.5.0-499.x86_64.rpm
[docker]$ 
```
and then execute the *docker_build.sh* script with the name and location of the extracted RPM file.
```text
[docker]$ ./docker_build.sh areplicate-2022.5.0-499.x86_64.rpm
Sending build context to Docker daemon  333.3MB
Step 1/26 : FROM centos:7
 ---> eeb6ee3f44bd
Step 2/26 : ARG user=attunity
 ---> Running in 163e91f2cbf9
Removing intermediate container 163e91f2cbf9
 ---> f986da4fb365
Step 3/26 : ARG group=attunity
 ---> Running in b6a626be1d1f
Removing intermediate container b6a626be1d1f
 ---> 991c39d19d18
Step 4/26 : ARG passwd=AttunityAdmin123
 ---> Running in dbee866f3011
Removing intermediate container dbee866f3011
 ---> 43972b008a67
...
...
...
**** INSTALLING REPLICATE ****
Loaded plugins: fastestmirror, ovl
Examining /tmp/replicate.rpm: areplicate-2022.5.0-499.x86_64
Marking /tmp/replicate.rpm to be installed
Resolving Dependencies
--> Running transaction check
---> Package areplicate.x86_64 0:2022.5.0-499 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

================================================================================
 Package           Arch          Version                Repository         Size
================================================================================
Installing:
 areplicate        x86_64        2022.5.0-499           /replicate        424 M

Transaction Summary
================================================================================
Install  1 Package

Total size: 424 M
Installed size: 424 M
...
...
...
Step 24/26 : EXPOSE 3552
 ---> Running in db875271d859
Removing intermediate container db875271d859
 ---> 66186935beb3
Step 25/26 : EXPOSE 3550
 ---> Running in 82ef0e8569c1
Removing intermediate container 82ef0e8569c1
 ---> cccc75aa26f7
Step 26/26 : CMD /home/attunity/bin/start-replicate.sh && bash
 ---> Running in 3307bac17668
Removing intermediate container 3307bac17668
 ---> 1334e42b722e
Successfully built 1334e42b722e
Successfully tagged replicate:k8s
[docker]$ 

```
> Note: The script *repldrivers.sh* is used during the `docker build` process. It updates the 
> base image operating system and installs ODBC drivers for MySQL, PostgreSQL, 
> SQL Server, Snowflake, and Databricks. Depending on your requirements, you might decide
> not to install all of these, or install others.

> Note: The script *start-replicate.sh* is copied into and used by 
> the docker image that is generated. It installs SSL certs and/or the Replicate 
> license if they are provided at runtime, and starts the Qlik Replicate server.
> You should review this script for details: it looks in specific locations for the 
> SSL certs and Qlik Replicate license.
