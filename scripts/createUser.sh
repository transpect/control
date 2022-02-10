#!/bin/bash

usage() { echo "Usage: $0 -u username -a path/to/ca-certs [-p password] [-d days]" 1>&2; exit 1; }

while getopts ":u:a:" o; do
    case "${o}" in
	u)
	    username=${OPTARG}
	    [ -z "$username" ] || usage
	    ;;
	a)	    
	    capath=${OPTARG}
	    [ -z "$capath" ] || usage
	    ;;
	p)
	    password=${OPTARG}
	    [ -z "$password" ] || password="xxxx"
	    ;;
	d)
	    days=${OPTARG}
	    [ -z "$days" ] || days="365"
	    ;;
	*)
	    usage
	    ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${username}" ] || [ -z "${capath}" ]; then
    usage
fi

echo ${username}
echo ${capath}
echo ${password}
echo ${days}

openssl genrsa -aes256 -passout pass:${password} -out ${username}.pass.key 4096
openssl rsa -passin pass:${password} -in ${username}.pass.key -out ${username}.key
rm ${username}.pass.key

openssl req -new -key ${username}.key -out ${username}.csr

openssl x509 -req -days ${days} -in ${username}.cst -CA ${capath}/ca.pem -CAkey ${capath}/ca.key -out ${username}.pem
echo "${username}.pem created"

cat ${username}.key ${username}.pem ca.pem > ${username}.full.pem
echo "${username}.full.pem created"

openssl pkcs12 -export -out ${username}.full.pfx -inkey ${username}.key -in ${username}.pem -certfile ${capath}/ca.pem
echo "${username}.full.pfx created"
