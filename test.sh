#!/bin/bash

declare -A svcs=( ["3000"]="grafana" ["3001"]="graphite" ["9090"]="prometheus" ["9100"]="node_exporter" ["9108"]="graphite_exporter" )

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

for portnum in "${!svcs[@]}"; 
do 
	#echo "$portnum - ${svcs[$portnum]}"; 
	echo -n "Testing  ${svcs[$portnum]} ..."
	CHECK=`curl --connect-timeout 2 --max-time 2 -X GET http://localhost:${portnum} >/dev/null 2>&1; echo $?`
	if [[ $CHECK == 0 ]]; then
		printf "\t${GREEN}PASS${NC}\n"
	else
		printf "\t${RED}FAIL${NC}\n"
	fi
done


echo -n "Testing datasource creation in Grafana"
DS=`curl -s -X GET --insecure -H "Content-Type: application/json" http://admin:admin@localhost:3000/api/datasources | jq -r '.[]| .name'`
if [[ $DS == "ds01" ]]; then
	printf "\t${GREEN}PASS${NC}\n"
else
	printf "\t${RED}FAIL${NC}\n"
fi


echo -n "Testing dashboard creation in Grafana"
DB=`curl -s -X GET --insecure -H "Content-Type: application/json" http://admin:admin@localhost:3000/api/search?query=Devops%20Test | jq -r '.[]|.title'`
if [[ ! -z $DB ]]; then
	printf "\t${GREEN}PASS${NC}\n"
else
	printf "\t${RED}FAIL${NC}\n"
fi


