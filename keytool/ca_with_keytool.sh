#!/usr/bin/env bash

caroot_pw=password
caim_pw=password
endpoint_pw=password
trust_pw=password
base_dn="dc=net,dc=example,ou=ca-tests,c=DE"

name_server=localhost
name_client=client@example.net

## Create Root-CA private key and certificate
keytool -genkeypair \
  -keystore caroot.keystore -storepass "$caroot_pw" \
  -alias root \
  -dname "$base_dn,cn=rootca" \
  -ext BasicConstraints:critical=ca:true \
  -ext KeyUsage:critical=keyCertSign,cRLSign \
  -sigalg SHA256withRSA -keyalg RSA -keysize 3072

## Add Root CA public certificate to trust store
keytool -export \
  -keystore caroot.keystore -storepass "$caroot_pw" \
  -alias root |
  keytool -import \
    -keystore trust.keystore -storepass "$trust_pw" \
    -alias root \
    -noprompt

## Create Intermediate-CA private key and certificate
keytool -genkeypair \
  -keystore caintermediate.keystore -storepass "$caim_pw" \
  -alias intermediate \
  -dname "$base_dn,cn=intermediateca" \
  -keyalg RSA -keysize 3072

keytool -export \
  -keystore caroot.keystore -storepass "$caroot_pw" \
  -alias root |
  keytool -import \
    -keystore caintermediate.keystore -storepass "$endpoint_pw" \
    -alias root \
    -noprompt
    
keytool -certreq \
  -keystore caintermediate.keystore -storepass "$caim_pw" \
  -alias intermediate |
  keytool -gencert \
    -keystore caroot.keystore -storepass "$caroot_pw" \
    -alias root \
    -ext BasicConstraints:critical=ca:true \
    -ext KeyUsage:critical=keyCertSign,cRLSign \
    -sigalg SHA256withRSA |
    keytool -importcert \
      -keystore caintermediate.keystore -storepass "$caim_pw" \
      -alias intermediate \
      -noprompt

keytool -delete \
  -keystore caintermediate.keystore -storepass "$endpoint_pw" \
  -alias root
## Add Intermediate CA public certificate to trust store
keytool -export \
  -keystore caintermediate.keystore -storepass "$caim_pw" \
  -alias intermediate |
  keytool -import \
    -keystore trust.keystore -storepass "$trust_pw" \
    -alias intermediate \
    -noprompt \
    -trustcacerts

## Create Server endpoint private key and certificate
keytool -genkeypair \
  -keystore server.keystore -storepass "$endpoint_pw" \
  -alias server \
  -dname "$base_dn,cn=$name_server" \
  -keyalg RSA -keysize 2048

keytool -certreq \
  -keystore server.keystore -storepass "$endpoint_pw" \
  -alias server |
  keytool -gencert \
    -keystore caintermediate.keystore -storepass "$caim_pw" \
    -alias intermediate \
    -ext KeyUsage:critical=digitalSignature,keyEncipherment \
    -ext ExtendedKeyUsage=serverAuth \
    -ext san="dns:$name_server" \
    -sigalg SHA256withRSA |
    keytool -importcert \
      -keystore server.keystore -storepass "$endpoint_pw" \
      -alias server \
      -noprompt \
      -trustcacerts

## Create Client endpoint private key and certificate
keytool -genkeypair \
  -keystore client.keystore -storepass "$endpoint_pw" \
  -alias client \
  -dname "$base_dn,emailaddress=$name_client" \
  -keyalg RSA -keysize 2048

keytool -certreq \
  -keystore client.keystore -storepass "$endpoint_pw" \
  -alias client |
  keytool -gencert \
    -keystore caintermediate.keystore -storepass "$caim_pw" \
    -alias intermediate \
    -ext KeyUsage:critical=digitalSignature,keyEncipherment \
    -ext ExtendedKeyUsage=clientAuth,emailProtection \
    -ext san=email:$name_client \
    -sigalg SHA256withRSA |
    keytool -importcert \
      -keystore client.keystore -storepass "$endpoint_pw" \
      -alias client \
      -noprompt

# List content of generated keystores
keytool -list \
  -keystore trust.keystore -storepass "$trust_pw"
keytool -list \
  -keystore caroot.keystore -storepass "$endpoint_pw"
keytool -list \
  -keystore caintermediate.keystore -storepass "$endpoint_pw"
keytool -list \
  -keystore server.keystore -storepass "$endpoint_pw"
keytool -list \
  -keystore client.keystore -storepass "$endpoint_pw"
