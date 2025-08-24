#!/usr/bin/env bash
CANAME=ExampleOrg_RootCA
BASEDN="/O=Example Org"

# create a directory
mkdir -p $CANAME
cd $CANAME || exit

# create CA certificate with 4096bit rsa key, 1826 days = 5 years
args_create_ca=(
  -x509
  -new
  -subj   "$BASEDN/CN=$CANAME"
  -days   1826
  -newkey rsa:4096
  -noenc
  -keyout "$CANAME.key"
  -out    "$CANAME.crt"
)
openssl req "${args_create_ca[@]}"
