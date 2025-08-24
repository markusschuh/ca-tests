#!/usr/bin/env bash
CANAME=ExampleOrg_RootCA

cd $CANAME || exit

MYCERT=$1

args_sign_endpoint=(
  -in     "$MYCERT.csr"
  -req
  -days   730
  -copy_extensions copyall
  -CA     "$CANAME.crt"
  -CAkey  "$CANAME.key"
  -CAcreateserial
  -out    "$MYCERT.crt"
)
openssl x509 "${args_sign_endpoint[@]}"
