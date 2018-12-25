#!/bin/bash
# Author: Y Melo
# Date: 22 Dec, 2018
# Description:
#   The main function of this script is just get a the output of mysql and split into multiple chuncks
#   appending 'workspace://SpacesStore/' to the beggining of the line
#   remember to remove the first line from the first file.
#   This script can be improved and more automated, but I just thing it's overkill.
# Pre-reqs:
# Need mysql cmd installed.
# It works in WSL (Windows Subsystem for linux). 

# limit of lines per file 
lines=10000
# limit of the database return
# 1 - true  > You Don't know your transaction id
# 0 - false > You know and have set it in the var bellow.
IDK_MYTRANSACTID=1
transact_id=5175780
limit_out=10000000
query_getNodes="./get-AlfNodeRef.sql"
query_getTransactID="./get-BigTransactions.sql"
dest_path="./output/tid_${transact_id}"
dest_file="${dest_path}/part_"
# DB Data
db_host="db.mysql.com"
db_user="alfresco"
db_schema="alfresco"
db_ssl_ca="./ssl-ca.crt"

if [[ ! -d ${dest_path} ]]; then
  echo "Path not found.. creating dir ${dest_path}" 
  mkdir -p ${dest_path}
else
  echo 'Path exists.'
fi;
echo "Files will be saved in ${dest_path}"
sleep 2

if [[ IDK_MYTRANSACTID -eq 1 ]]; then
  mysql -u  ${db_user} -h ${db_host} ${db_schema} --ssl-ca ${db_ssl_ca} -p < ${query_getTransactID}
  
  read -p "Transact id: " transact_id
  read -p "Limit (count value: Defeault 10m) : " limit_out
fi
limit_out=${limit_out:-10000000}

# If your server doesn't use ssl remember to remove --ssl-ca
mysql -u  ${db_user} -h ${db_host} ${db_schema} --ssl-ca ${db_ssl_ca} -p -e "select uuid from alf_node where transaction_id=${transact_id} limit ${limit_out};" >  >(sed "s/^/workspace:\/\/SpacesStore\//"  |  split -l ${lines} - ${dest_file} )
# OR 
# mysql -u  ${db_user} -h ${db_host} ${db_user} --ssl-ca ${db_ssl_ca} -p < ${query_file}>  >(sed "s/^/workspace:\/\/SpacesStore\//"  |  split -l ${lines} - $dest_file )
