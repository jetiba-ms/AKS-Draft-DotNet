#!/bin/bash
clear
echo "start"
#add-apt-repository ppa:rmescandon/yq
#apt update
#apt install yq
echo "everything is installed"
cd charts/$1
echo "move to folder charts/"$1
yq d -i values.yaml resources
yq w -i values.yaml service.internalPort 8080
yq w -i values.yaml service.debugPort 5005
yq w -i values.yaml env.host $2
yq w -i values.yaml env.database $3
yq w -i values.yaml env.username $4
yq w -i values.yaml env.password $5
echo "end"
cd templates
yq w -i deployment.yaml spec.template.spec.containers[0].ports[+].containerPort {{ .Values.service.debugPort }}