#!/usr/bin/env bash

if ! command -v keytool >/dev/null 2>&1
then
    echo "ERROR: command ´keytool´ could not be found!"
    exit 1
fi

if ! command -v openssl >/dev/null 2>&1
then
    echo "ERROR: command ´openssl´ could not be found!"
    exit 1
fi

### functions

##
## list entries keystore
##
## input: associative array

list_keystore() {

  local store=$1 pass=$2

  echo "List content of keystore '$store':"
  keytool -list \
    -keystore "$store" -storepass "$pass"
  echo
}
#
##
## print certificate details of entry from keystore
##
## input: associative array

list_cert() {

  local store=$1 pass=$2 alias=$3

  echo "Print certificate details of alias '$alias' in keystore '$store':"
  keytool -list \
    -keystore "$store" -storepass "$pass" \
    -alias "$alias" -rfc |
      openssl x509 -noout -text
  echo
}

##
## main
##

list_keystore client.keystore password1
list_keystore server.keystore password2

list_keystore client.truststore changeit
list_keystore server.truststore changeit

list_cert server.truststore changeit client
list_cert client.truststore changeit server
