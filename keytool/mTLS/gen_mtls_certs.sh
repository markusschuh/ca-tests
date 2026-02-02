#!/usr/bin/env bash

base_dn="dc=net,dc=example,ou=test"
keyalg=RSA
keysize=2048
validity=100

declare -A client_cert=(
  [dn]="$base_dn,cn=client"
  [alias]=client
  [keystore]=client.keystore
  [keystore_pw]=password1
  [truststore]=server.truststore
  [truststore_pw]=changeit
  [keyalg]="$keyalg"
  [keysize]="$keysize"
  [validity]="$validity"
)

declare -A server_cert=(
  [dn]="$base_dn,cn=server"
  [alias]=server
  [keystore]=server.keystore
  [keystore_pw]=password2
  [truststore]=client.truststore
  [truststore_pw]=changeit
  [keyalg]="$keyalg"
  [keysize]="$keysize"
  [validity]="$validity"
)

if ! command -v keytool >/dev/null 2>&1
then
    echo "ERROR: command ´keytool´ could not be found!"
    exit 1
fi

### functions

##
## generate certificate and save in keystore
##
## input: associative array

generate_certificate() {

  local -n cert=$1

  # generate private key and certificate
  # write them to keystore
  keytool -genkeypair \
    -keyalg "${cert[keyalg]}" -keysize "${cert[keysize]}" \
    -keystore "${cert[keystore]}" -storepass "${cert[keystore_pw]}" \
    -validity "${cert[validity]}" \
    -alias "${cert[alias]}" \
    -dname "${cert[dn]}"
}

##
## generate truststore
##
## input:  associative array
## prereq: accessible keystore with the given alias

generate_truststore() {

  local -n cert=$1

  # export the public certificate and import in truststore
  keytool -exportcert \
    -keystore "${cert[keystore]}" -storepass "${cert[keystore_pw]}" \
    -alias "${cert[alias]}" |
      keytool -importcert \
        -keystore "${cert[truststore]}" -storepass "${cert[truststore_pw]}" \
        -alias "${cert[alias]}" \
        -noprompt
}

##
## main
##

generate_certificate client_cert
generate_certificate server_cert

generate_truststore client_cert
generate_truststore server_cert
