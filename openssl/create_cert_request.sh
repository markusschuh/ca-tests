#!/usr/bin/env bash
CANAME=ExampleOrg_RootCA
BASEDN="/O=Example Org"

cd $CANAME || exit

# create certificate for service
MYCERT=server.local
MYALTS="DNS:$MYCERT,DNS:cluster.local,IP:192.168.0.1"

args_create_endpoint=(
  -subj   "$BASEDN/CN=$MYCERT"
  -addext "subjectAltName=$MYALTS"
  -addext "subjectKeyIdentifier=hash"
  -addext "keyUsage=digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment"
  -addext "extendedKeyUsage=serverAuth,clientAuth"
  -addext "basicConstraints=CA:FALSE"
  -newkey rsa:2048
  -noenc
  -keyout "$MYCERT.key"
  -out    "$MYCERT.csr"
)
openssl req "${args_create_endpoint[@]}"
