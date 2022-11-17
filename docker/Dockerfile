FROM centos:7
ARG user=attunity
ARG group=attunity
ARG passwd=AttunityAdmin123
ARG instdir=/opt
ARG datadir=/data
ARG installfile=file_not_set
ARG rpmenv="user=$user group=$group pass=$passwd data=$datadir verbose=true debug="

LABEL maintainer="John Neal <john.neal@qlik.com>"


ADD repldrivers.sh /tmp/
RUN echo "**** INSTALLING ODBC Drivers ****"; \
    /tmp/repldrivers.sh \
    rm /tmp/repldrivers.sh

RUN echo "**** INSTALLING JAVA ****"; \
    yum $disablerepo -y install java-1.8.0-openjdk.x86_64; \
    echo "export JAVA_HOME=/usr/lib/jvm/jre-1.8.0-openjdk" >> /etc/profile; \
    echo "export JRE_HOME=/usr/lib/jvm/jre" >> /etc/profile; \
    grep -i "J*_HOME" /etc/profile; \
    echo "**** JAVA INSTALLATION COMPLETE ****"

COPY $installfile /tmp/replicate.rpm
RUN mkdir $datadir; \
    chmod 775 $datadir;  \
    echo "**** INSTALLING REPLICATE ****"; \
    export $rpmenv;yum -y install /tmp/replicate.rpm; \
    rm /tmp/replicate.rpm; \
    chown $user:$group $datadir; \
    mkdir -p /home/attunity/bin; chown -R attunity:attunity /home/attunity; \
    # set password for root and the attunity user
    echo "root:welcome1" | chpasswd; \
    echo "attunity:welcome1" | chpasswd;
# can't do this until after Replicate is installed.
ADD --chown=attunity:attunity start-replicate.sh /home/attunity/bin/
RUN chmod +x /home/attunity/bin/*
#
# workaround for MS ODBC17 issue with Synapse. Won't be needed
# once ODBC17 becomes the default for that endpoint.
#
RUN echo "export SSL_CERT_FILE=/etc/pki/tls/cert.pem" >> $instdir/attunity/replicate/bin/site_arep_login.sh
RUN echo "===== site_arep_login ====="; cat $instdir/attunity/replicate/bin/site_arep_login.sh
#

# clean up
RUN yum -y update; \
    yum clean all; \
    rm -rf /var/cache/yum; 

# configure the environment
WORKDIR $instdir/attunity/replicate/bin
ENV PATH="$instdir/attunity/replicate/bin:/opt/mssql-tools/bin:$PATH"
ENV LD_LIBRARY_PATH="$instdir/attunity/replicate/lib:/usr/lib64:/opt/microsoft/msodbcsql/lib64/:/usr/pgsql-12/lib:$LD_LIBRARY_PATH"

#
USER $user:$group
EXPOSE 3552
EXPOSE 3550
# start the Replicate server. Note that the server is started as a
# system service. arep.ctl returns after starting, and docker will exit
# at that point. To prevent this, we execute a bash shell after a 
# successful start of Replicate. This has added benefit of providing a
# tty we can connect to for troubleshooting. Caution: if you exit the
# bash shell, the container will terminate.
CMD /home/attunity/bin/start-replicate.sh && bash || bash

