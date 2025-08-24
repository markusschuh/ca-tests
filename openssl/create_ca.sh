#!/usr/bin/env bash
CANAME=ExampleOrg_RootCA
BASEDN="/O=Example Org"

# create a directory
mkdir -p $CANAME
cd $CANAME || exit

# create CA certificate with 4096bit rsa key, 1826 days = 5 years
args_create_ca=(
  -newkey rsa:4096
  -aes256
  -keyout "$CANAME.key"
  -x509
  -new
  -sha256
  -days   1826
  -subj   "$BASEDN/CN=$CANAME"
  -out    "$CANAME.crt"
)
openssl req "${args_create_ca[@]}"
