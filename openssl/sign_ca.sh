#!/usr/bin/env bash
CANAME=Example_RootCA

cd $CANAME || exit

MYCERT=$1

args_sign_endpoint=(
  -req
  -CA     "$CANAME.crt"
  -CAkey  "$CANAME.key"
  -in     "$MYCERT.csr"
  -out    "$MYCERT.crt"
  -CAcreateserial
  -days   730
  -sha256
  -copy_extensions copyall
)
openssl x509 "${args_sign_endpoint[@]}"
