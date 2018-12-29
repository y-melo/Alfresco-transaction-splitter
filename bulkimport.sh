#!/bin/bash

# Author: Z Mahmood 
# Version 0.2.0
# Date: Dec 29, 2018
# Description: 
# This program will get all folders inside ../stating and 
# it will import into alfresco/Document Root/Splitter
# notice that you need to manually create the folder and the rule in alfresco.
# xmlint is used to verify when bulkimport finished. make sure it's installed.
# install xmlint on ubuntu - sudo apt-get install libxml2-utils
#
# The usage of the curl command will leak the password in the process list.

# Variables that you need to change 
alfserver="localhost:8080"
username="Admin"
password="Alfresco_Password"

# Making some basic validation...
# Check if xmlint is installed.
command -v xmlint >/dev/null 2>&1 || { echo >&2 "It requires xmlint but it's not installed.  Aborting."; exit 1; }
# Check if alfresco is runnig
$(pgrep java) 2>&1 ||	{ echo >&2 "Java process not found. Make sure alfresco is running. Aborting";	exit 1;}


echo "Alfresco running on PID $(pgrep java)."
# Variables 
batchName= $transact_id
rootfolder="/opt/splitter"
logpath="$rootfolder/logs"
importDirectory="$rootfolder/staging"
targetpath="/splitter/"
#filemodes: SKIP | REPLACE | ADD_VERSION
filemode="SKIP"
batchsize=20
threads=4
waitfor=60
starttime=$(date +%Y-%m-%d_%H:%M:%S)
logfile="$starttime-import"

# If import folder is empty then stop
if [ `ls $importDirectory/ | wc -m` == "0" ]; then
	echo "Folder $importDirectory is empty" >&2
	exit 0
fi

echo "_________________________ Importing ______________________________" >>$logpath/splitter.log
echo "TargetPath: $targetpath" >>$logpath/splitter.log
echo "sourceDirectory: $importDirectory" >>$logpath/splitter.log
echo "---------------------------" >>$logpath/splitter.log

curlstart="curl -v -u $username:$password -L POST --url \"$alfserver/alfresco/s/bulkfsimport/initiate\" --data \"targetPath=$targetpath&sourceDirectory=$importDirectory&existingFileMode=$filemode&batchSize=$batchsize&numThreads=$threads\" >$logpath/$logfile.html 2>/dev/null"

echo "$starttime: $curlstart" >>$logpath/splitter.log
eval $curlstart
while true; do
	echo "Checking Curl Status..."
	curlstatus="curl -u $username:$password $alfserver/alfresco/service/bulkfsimport/status.xml >$logpath/$logfile.xml 2>/dev/null"
# echo $curlstatus
	eval $curlstatus
	CurrentStatus=$(xmllint --xpath 'string(//CurrentStatus)' $logpath/$logfile.xml)
	echo $CurrentStatus
	if [ "$CurrentStatus" == "Idle" ]
	then
		break
	fi
	sleep $waitfor
done

echo "Moving $importDirectory/tid* TO /opt/splitter/done/"  >>$logpath/splitter.log
mv $importDirectory/tid* "/opt/splitter/done/"

exit 0