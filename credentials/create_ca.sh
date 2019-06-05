#!/bin/bash

ca_password=root_password
subject="/CN=Kafka-CA"

key=ca.key
req=ca.csr
crt=ca.crt

echo ""
echo "======================="
echo "create root certificate"
echo "======================="
echo ""

printf "\n\ncreated CA key and CA csr\n=========================\n\n"
openssl req -newkey rsa:1024 -sha1 -passout pass:${ca_password} -keyout ${key} -out ${req} -subj ${subject} \
	-reqexts ext \
	-config <(cat /etc/ssl/openssl.cnf <(printf "\n[ext]\nbasicConstraints=CA:TRUE,pathlen:0"))
[ $? -eq 1 ] && echo "unable to create CA key and csr" && exit

printf "\n\nverify CA key\n=============\n\n"
openssl rsa -check -in ${key} -passin pass:${ca_password} 
[ $? -eq 1 ] && echo "unable to verify CA key" && exit

printf "\n\nverify CA csr\n=============\n\n"
openssl req -text -noout -verify -in ${req}
[ $? -eq 1 ] && echo "unable to verify CA csr" && exit

printf "\n\nself-sign CA csr\n================\n\n"
openssl x509 -req -in ${req} -sha1 -days 365 -passin pass:${ca_password} -signkey ${key} -out ${crt} \
	-extensions ext \
	-extfile <(cat /etc/ssl/openssl.cnf <(printf "\n[ext]\nbasicConstraints=CA:TRUE,pathlen:0"))
[ $? -eq 1 ] && echo "unable to self-sign CA csr" && exit

printf "\n\nverify CS crt\n=============\n\n"
openssl x509 -in ${crt} -text -noout
[ $? -eq 1 ] && echo "unable to verify CA crt" && exit

printf "\n\n"
