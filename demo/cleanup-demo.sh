#! /bin/bash


kubectl delete pod dbloadgen mysqldb postgresdb replhost

kubectl delete service dbloadgen mysqldb postgresdb replhost
