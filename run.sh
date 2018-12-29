#!/bin/bash
# Author: Y Melo
# Version: 0.2.0
# Date: Dec 29, 2018
# Description:
#   The main function of this script is just get a the output of mysql and split into multiple chuncks
#   appending 'workspace://SpacesStore/' to the beggining of the line
#   remember to remove the first line from the first file.
#   This script can be improved and more automated, but I just thing it's overkill.
# Pre-reqs:
# Need mysql cmd installed.
# It works in WSL (Windows Subsystem for linux).
#
# MySQL cmdline validation
command -v mysql >/dev/null 2>&1 || { echo >&2 "this script requires 'mysql' but it's not installed. Aborting."; exit 1; }

# Variables 
  # limit of lines per file 
  lines=10000
  limit_out=10000000
  # limit of the database return
  # 1 - true  > You Don't know your transaction id
  # 0 - false > You know and have set it in the var bellow.
  IDK_MYTRANSACTID=1
  transact_id=4116488
  query_getNodes="./get-AlfNodeRef.sql"
  query_getTransactID="./get-BigTransactions.sql"
  # DB Data
  db_host="mysql.database.com"
  db_user="alfresco"
  db_schema="alfresco"
  db_ssl_ca="./azmysql.crt"

if [[ $IDK_MYTRANSACTID -eq 1 ]]; then
  echo "Enter your mysql password..."
  mysql -u  ${db_user} -h ${db_host} ${db_schema} --ssl-ca ${db_ssl_ca} -p < ${query_getTransactID}

  read -p "Transact id: " transact_id
  read -e -i "${limit_out}" -p "Limit (count value: Defeault 10m) : " input
fi
limit_out=${input:-$limit_out}

dest_path="./output/tid_${transact_id}"
dest_file="${dest_path}/part_"

if [[ ! -d ${dest_path} ]]; then
  echo "Path not found.. creating dir ${dest_path}"  >&2
  mkdir -p ${dest_path}
else
  echo 'Path exists.'
fi

# If your server doesn't use ssl remember to remove --ssl-ca
echo "Enter your mysql password again..."
mysql -u  ${db_user} -h ${db_host} ${db_schema} --ssl-ca ${db_ssl_ca} -p -e "select uuid from alf_node where transaction_id=${transact_id} limit ${limit_out};" >  >(sed "s/^/workspace:\/\/SpacesStore\//"  |  split -l ${lines} - ${dest_file} )

# OR 
# mysql -u  ${db_user} -h ${db_host} ${db_user} --ssl-ca ${db_ssl_ca} -p < ${query_file}>  >(sed "s/^/workspace:\/\/SpacesStore\//"  |  split -l ${lines} - $dest_file)
exit 0