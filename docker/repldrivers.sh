#! /bin/bash 
#
# be sure to update Replicate environment
#
# PATH="/opt/mssql-tools/bin:$PATH"
# LD_LIBRARY_PATH="/opt/microsoft/msodbcsql17/lib64/:/usr/pgsql-12/lib:$LD_LIBRARY_PATH"


mysqlodbc=https://dev.mysql.com/get/Downloads/Connector-ODBC/8.0/mysql-connector-odbc-8.0.25-1.el7.x86_64.rpm
postgresyum=https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
databricks=https://databricks-bi-artifacts.s3.us-east-2.amazonaws.com/simbaspark-drivers/odbc/2.6.22/SimbaSparkODBC-2.6.22.1037-LinuxRPM-64bit.zip
snowflake_version=2.25.4
snowflake=https://sfc-repo.snowflakecomputing.com/odbc/linux/${snowflake_version}/snowflake-odbc-${snowflake_version}.x86_64.rpm
oracleinstantclient=./oracle-instantclient12.2-basic-12.2.0.1.0-1.x86_64.rpm
oraclesqlplus=./oracle-instantclient12.2-sqlplus-12.2.0.1.0-1.x86_64.rpm
oracleodbc=./oracle-instantclient12.2-odbc-12.2.0.1.0-2.x86_64.rpm


#
# Oracle drivers cannot be accessed remotely. You will
# need to accept the license agreement and download locally.
#
install_oracle() {
   # oracle
   echo "**** INSTALLING ORACLE DRIVERS ***"
   yum -y install $oracleinstantclient
   yum -y install $oraclesqlplus
   yum -y install $oracleodbc
   ln -s /usr/lib/oracle/12.2/client64/lib/libclntsh.so.12.* \
                 /usr/lib/oracle/12.2/client64/lib/libclntsh.so
}

install_mysql() {
   # mysql
   echo "**** INSTALLING MYSQL DRIVERS ***"
   yum  -y install mysql
   yum  -y install $mysqlodbc
}

install_postgres() {
   # postgres
   echo "**** INSTALLING POSTGRES DRIVERS ***"
   yum  -y install $postgresyum;  \
   yum  -y install postgresql12
   yum  -y install postgresql12-odbc
   {
      echo "" 
      echo "[PostgreSQL]" 
      echo "Description=ODBC for PostgeSQL target" 
      echo "Driver=/usr/pgsql-12/lib/psqlodbcw.so" 
      echo "Driver64=/usr/pgsql-12/lib/psqlodbcw.so" 
      echo "" 
      echo "[PostgreSQL Unicode(x64)]" 
      echo "Description=ODBC for PostgeSQL source" 
      echo "Driver=/usr/pgsql-12/lib/psqlodbcw.so" 
      echo "Driver64=/usr/pgsql-12/lib/psqlodbcw.so" 
      echo "" 
   } >> /etc/odbcinst.ini
}

install_mssql() {
   # SQL Server
   echo "**** INSTALLING SQL SERVER DRIVERS ***"
   curl https://packages.microsoft.com/config/rhel/7/prod.repo > /etc/yum.repos.d/mssql-release.repo
   ACCEPT_EULA=Y yum -y install msodbcsql17
   # for bcp and sqlcmd 
   ACCEPT_EULA=Y yum -y install mssql-tools
   #ls  -la /opt/microsoft/msodbcsql/lib64/libmsodbc*
   #ln -s $(ls /opt/microsoft/msodbcsql/lib64/libmsodbcsql-13.1.so.*) \
   #         /opt/microsoft/msodbcsql/lib64/libmsodbcsql-13.1.so.0.0
}

install_snowflake() {
   # Snowflake
   echo "**** INSTALLING SNOWFLAKE DRIVERS ***"
   yum -y install $snowflake
}

install_databricks() {
   # Databricks
   { # do this work in a subshell
      echo "**** INSTALLING DATABRICKS DRIVERS ***"
      mkdir /tmp/databricks
      cd /tmp/databricks 
      wget --no-verbose $databricks
      unzip Simba*.zip
      yum -y install simba*.rpm
      rm -rf /tmp/databricks
      {
         echo "" 
         echo "[Simba Spark ODBC Driver]" 
         echo "Description=Simba Spark ODBC Driver (64-bit)" 
         echo "Driver=/opt/simba/spark/lib/64/libsparkodbc_sb64.so" 
         echo "" 
      } >> /etc/odbcinst.ini
   }
}

echo "**** UPDATING THE OS ***" 
yum -y install deltarpm wget unzip
yum -y update  ca-certificates 
yum -y install epel-release 
rpm --import /etc/pki/rpm-gpg/*GPG* 
yum -y update 


echo "**** INSTALLING UnixODBC ***" 
yum -y install unixODBC
mv /etc/odbcinst.ini /etc/odbcinst.ini.org
touch /etc/odbcinst.ini

# install odbc drivers
install_mysql
install_postgres
install_mssql
install_snowflake
install_databricks

# Oracle files must be downloaded locally
#install_oracle

# clean up
echo "**** CLEANING UP ***" 
yum -y update
yum clean all
rm -rf /var/cache/yum

