#!/bin/bash

if [ $# -lt 1 ]; then
  echo "usage: $0 hostname"
  exit
fi

HOSTNAME=$1
shift

# TODO verify intermediate.crt, intermediate.key, ca.crt exists

CA_PW=root_password
IN_PW=intermediate_password
B_PW=super_secret

i=${HOSTNAME}

SUBJECT="/C=US/ST=Minneasota/L=Minneapolis/O=OPI/OU=RTD/CN=${i}"
key=${i}.key
req=${i}.req
crt=${i}.crt
cnf=${i}.cnf
keystore=${i}.keystore.jks

printf "\ngenerating key, csr, crt, and p12 file for $i\n\n"

printf "generate key\n============\n\n"
openssl genrsa -aes128 -passout pass:${B_PW} -out ${key} 3072
[ $? -eq 1 ] && echo "unable to generate key for ${i}." && exit

printf "\n\nverify key\n==========\n\n"
openssl rsa -check -in ${key} -passin pass:${B_PW} 
[ $? -eq 1 ] && echo "unable to verify key for ${i}." && exit

printf "\n\ngenerate csr\n==========\n\n"
openssl req -new -sha256 -key ${key} -passin pass:${B_PW} -out ${req} -subj "${SUBJECT}" \
	-reqexts SAN \
	-config <(cat /etc/ssl/openssl.cnf <(printf "\n[SAN]\nsubjectAltName=DNS:${i}\nextendedKeyUsage=serverAuth,clientAuth"))
[ $? -eq 1 ] && echo "unable to generate csr for ${i}." && exit

printf "\n[v3_ca]\nsubjectAltName=DNS:${i}\nextendedKeyUsage=serverAuth,clientAuth" > ${cnf}

printf "\ncsr\n===\n\n"
openssl req -in ${req} -text -noout

[ $? -eq 1 ] && echo "unable to print certificate for ${i}." && exit

printf "\n\nsign csr\n========\n\n"

  #
  # sign the certificate request and extensions file
  #     openssl.cnf must have 'copy_extensions = copy'
  #     issues running on MacOS to get extensions into x509 from csr
  #
openssl x509 \
	-req \
	-CA intermediate.crt \
	-CAkey intermediate.key \
	-passin pass:$IN_PW \
	-in ${req} \
	-out ${crt} \
	-days 365 \
	-CAcreateserial \
        -extfile ${cnf} \
	-extensions v3_ca 
[ $? -eq 1 ] && echo "unable to sign the csr for ${i}." && exit

cat intermediate.crt ca.crt > chain.pem

openssl verify -CAfile chain.pem ${crt}
[ $? -eq 1 ] && echo "unable to verify certificate for ${i}." && exit

printf "\ncertificate\n===========\n\n"
openssl x509 -in ${crt} -text -noout
[ $? -eq 1 ] && echo "unable to print certificate for ${i}." && exit

  # combine key and certificate into a pkcs12 file
openssl pkcs12 -export -in ${crt} -inkey ${key} -passin pass:$B_PW -chain -CAfile chain.pem -name $i -out $i.p12 -passout pass:$B_PW
[ $? -eq 1 ] && echo "unable to crate pkcs12 file for ${i}." && exit

