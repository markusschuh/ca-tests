#!/usr/bin/env bash
CANAME=ExampleOrg_RootCA
BASEDN="/O=Example Org"

cd $CANAME || exit

# create certificate for service
MYCERT=server.local
MYALTS="DNS:$MYCERT,DNS:cluster.local,IP:192.168.0.1"

args_create_endpoint=(
  -out    "$MYCERT.csr"
  -keyout "$MYCERT.key"
  -subj   "$BASEDN/CN=$MYCERT"
  -addext "subjectAltName=$MYALTS"
  -addext "subjectKeyIdentifier=hash"
  -addext "keyUsage=digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment"
  -addext "extendedKeyUsage=serverAuth,clientAuth"
  -addext "basicConstraints=CA:FALSE"
  -nodes
  -newkey rsa:2048
)
openssl req "${args_create_endpoint[@]}"
