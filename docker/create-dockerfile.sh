#!/bin/bash

# Expect no parameters, but needs a drivers file.

dockerfile=temp_dockerfile
write_header()
{
echo "Writing the installation for replicate"
cat > $dockerfile << EOF
FROM centos:7

#install prequisits
RUN yum install -y unixODBC unzip
RUN rm -f /etc/odbcinst.ini

ADD areplicate-*.rpm /tmp/
RUN yum -y install /tmp/areplicate-*.rpm
RUN yum clean all
RUN rm -f /tmp/areplicate-*.rpm

ENV ReplicateDataFolder /replicate/data
ENV ReplicateAdminPassword ""
ENV ReplicateRestPort 3552
ADD start_replicate.sh /opt/attunity/replicate/bin/start_replicate.sh
RUN chmod 775 /opt/attunity/replicate/bin/start_replicate.sh
EOF

license=""
if [ -f license.json ]; then
license="license.json"
echo "Adding license file to Dockerfile"
echo "ADD $license /" >> $dockerfile
fi

cat >> $dockerfile << EOF
ENTRYPOINT /opt/attunity/replicate/bin/start_replicate.sh \${ReplicateDataFolder} \${ReplicateAdminPassword} \${ReplicateRestPort} $license ; tail -f /dev/null
EOF
}

check_driver_file_exists()
{
  filename=$1
  driver=$2
  if [ -z $filename ]; then
    echo "No file is specified in the drivers file for driver '$driver'."
    rm -f $dockerfile
    return 1
  fi
  if [ ! -f $filename ]; then
    echo "File '$filename', that is specified in the drivers file for '$driver', doesn't exist."
    rm -f $dockerfile
    return 1
  fi
}

check_necessary_file_exists()
{
  filename=$1
  driver=$2
  if [ ! -f $filename ]; then
    echo "File '$filename', that is necessary for the installation of '$driver', doesn't exist."
    rm -f $dockerfile
    return 1
  fi
}

install_sql_server()
{
filename=$1
version=$2
cat >> $dockerfile << EOF
ADD $filename /
RUN ACCEPT_EULA=Y yum -y --nogpgcheck install $filename
RUN ln -s /opt/microsoft/msodbcsql/lib64/libmsodbcsql-$version.so.* /opt/microsoft/msodbcsql/lib64/libmsodbcsql-$version.so.0.0
ENV LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/opt/microsoft/msodbcsql/lib64
RUN sed -i "/libmsodbcsql-$version.so.*/c\Driver=/opt/microsoft/msodbcsql/lib64/libmsodbcsql-$version.so.0.0" /etc/odbcinst.ini
RUN rm -f $filename
EOF
}

install_oracle()
{
check_necessary_file_exists "oracleclient.rsp" "oracle$version" || return $?
filename=$1
version=$2
cat >> $dockerfile << EOF
ADD oracleclient.rsp /oracleclient.rsp
RUN yum install -y libaio
ADD $filename /
RUN unzip $filename
RUN usermod -G attunity attunity
RUN mkdir /opt/oracle && chown -R attunity:attunity /opt/oracle
USER attunity
RUN /client/runInstaller -silent -ignorePrereq -waitforcompletion -responseFile /oracleclient.rsp
USER root
RUN /opt/oracle/oraInventory/orainstRoot.sh
ENV ORACLE_HOME=/opt/oracle/$version/client
ENV LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/opt/oracle/$version/client
RUN rm -rf $filename client oracleclient.rsp
EOF
}

install_mysql()
{
filename=$1
version=$2
cat >> $dockerfile << EOF
ADD $filename /
RUN yum install -y $filename
RUN rm -f $filename
RUN echo "[MySQL]" >> /etc/odbcinst.ini
RUN echo "Description     = ODBC for MySQL" >> /etc/odbcinst.ini
RUN echo "Driver          = /usr/lib/libmyodbc5.so" >> /etc/odbcinst.ini
RUN echo "Setup           = /usr/lib/libodbcmyS.so" >> /etc/odbcinst.ini
RUN echo "Driver64        = /usr/lib64/libmyodbc5.so" >> /etc/odbcinst.ini
RUN echo "Setup64         = /usr/lib64/libodbcmyS.so" >> /etc/odbcinst.ini
RUN echo "FileUsage       = 1" >> /etc/odbcinst.ini
EOF
}

install_postgres95()
{
cat >> $dockerfile << EOF
RUN yum install -y https://download.postgresql.org/pub/repos/yum/9.5/redhat/rhel-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm && yum install -y postgresql95-odbc postgresql95 postgresql95-libs
ENV LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/lib:/usr/lib64:/usr/pgsql-9.5/lib
RUN echo "[PostgreSQL]" >> /etc/odbcinst.ini
RUN echo "Description=ODBC for PostgreSQL" >> /etc/odbcinst.ini
RUN echo "Driver=/usr/pgsql-9.5/lib/psqlodbc.so" >> /etc/odbcinst.ini
RUN echo "Setup=/usr/pgsql-9.5/lib/libodbcpsqlS.so" >> /etc/odbcinst.ini
RUN echo "FileUsage=1" >> /etc/odbcinst.ini
EOF
}

install_db2luw()
{
check_necessary_file_exists "db2client.rsp" "db2luw$version" || return $?
filename=$1
version=$2
cat >> $dockerfile << EOF
ADD db2client.rsp /
ADD $filename /
RUN pushd /server_ese_u && ./db2setup -r /db2client.rsp && popd
ENV LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/opt/ibm/db2/V$version/lib64
RUN rm -rf server_ese_u db2client.rsp
RUN echo "[IBM DB2 ODBC DRIVER]" >> /etc/odbcinst.ini
RUN echo "Driver = /opt/ibm/db2/V$version/lib64/libdb2o.so" >> /etc/odbcinst.ini
RUN echo "fileusage=1" >> /etc/odbcinst.ini
RUN echo "dontdlclose=1" >> /etc/odbcinst.ini
EOF
}

generate_drivers()
{
    linenumber=0
    grep ^[^#].* drivers | sed -r 's/^([^[:space:]]*)\s*=\s*([^[:space:]]*)\s*$/\1 \2/' | \
    while read -r key value; do
    let "linenumber+=1"    
    echo "Writing the installation for $key"
    case $key in
    oracle12.1)
      check_driver_file_exists "$value" "$key" || return $?
      install_oracle "$value" "12.1" || return $?
    ;;
    sqlserver13.1)
      check_driver_file_exists "$value" "$key" || return $?
      install_sql_server "$value" "13.1" || return $?
    ;;
    mysql5.3)
      check_driver_file_exists "$value" "$key" || return $?
      install_mysql "$value" "15.3" || return $?
    ;;
    postgres9.5)
      install_postgres95 || return $?
    ;;
    db2luw11.1)
      check_driver_file_exists "$value" "$key" || return $?
      install_db2luw "$value" "11.1" || return $?
    ;;
    "")
    ;;
    *)
    echo drivers file has an invalid entry at line $linenumber.
    rm -f $dockerfile
    return 1
    esac
    done 
}

rm -f Dockerfile
write_header 
if [ -f drivers ]; then
  generate_drivers || exit $?
fi
mv $dockerfile Dockerfile
