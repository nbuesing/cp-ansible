#!/bin/bash

CA_PW=root_password
IN_PW=intermediate_password

subject="/CN=Kafka-intermediate"

key=intermediate.key
req=intermediate.csr
crt=intermediate.crt

echo ""
echo "==============================="
echo "create intermediate certificate"
echo "==============================="
echo ""

printf "\n\ncreated IN key and IN csr\n=========================\n\n"
openssl req -newkey rsa:1024 -sha1 -passout pass:${IN_PW} -keyout ${key} -out ${req} -subj ${subject}
	-extensions ca \
	-config <(cat /etc/ssl/openssl.cnf <(printf "\n[ext]\nbasicConstraints=CA:TRUE,pathlen:0"))
[ $? -eq 1 ] && echo "unable to create IN key and csr" && exit

printf "\n\nverify IN key\n=============\n\n"
openssl rsa -check -in ${key} -passin pass:${IN_PW} 
[ $? -eq 1 ] && echo "unable to verify IN key" && exit

printf "\n\nverify IN csr\n=============\n\n"
openssl req -text -noout -verify -in ${req}
[ $? -eq 1 ] && echo "unable to verify IN csr" && exit

printf "\n\nsign IN csr\n===========\n\n"
openssl x509 -req -CA ca.crt -CAkey ca.key -passin pass:${CA_PW} -in ${req} -sha1 -days 365 -out ${crt} -CAcreateserial \
	-extensions ext \
	-extfile <(cat /etc/ssl/openssl.cnf <(printf "\n[ext]\nbasicConstraints=CA:TRUE,pathlen:0"))
[ $? -eq 1 ] && echo "unable to sign IN csr" && exit

printf "\n\nverify CS crt\n=============\n\n"
openssl x509 -in ${crt} -text -noout
[ $? -eq 1 ] && echo "unable to verify IN crt" && exit

printf "\n\n"
