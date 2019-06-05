#!/bin/bash


declare -a MACHINES=("broker-1" "broker-2" "broker-3" "jumphost")
#declare -a MACHINES=("broker-1")

for i in ${MACHINES[@]}; do

  ./create_cert.sh ${i}

done
