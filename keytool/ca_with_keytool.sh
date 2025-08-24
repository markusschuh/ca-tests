#!/usr/bin/env bash

caroot_pw=password1
caim_pw=password2
endpoint_pw=password3
trust_pw=password4
base_dn="dc=net,dc=example,ou=ca-tests,c=DE"

keytool -genkeypair \
  -keystore caroot.keystore -storepass "$caroot_pw" \
  -alias root \
  -dname "$base_dn,cn=rootca" \
  -keyalg RSA

keytool -export \
  -keystore caroot.keystore -storepass "$caroot_pw" \
  -alias root |
  keytool -import \
    -keystore caintermediate.keystore -storepass "$caim_pw" \
    -alias root \
    -noprompt

keytool -genkeypair \
  -keystore caintermediate.keystore -storepass "$caim_pw" \
  -alias intermediate \
  -dname "$base_dn,cn=intermediateca" \
  -keyalg RSA

keytool -certreq \
  -keystore caintermediate.keystore -storepass "$caim_pw" \
  -alias intermediate \
  -keyalg RSA |
  keytool -gencert \
    -keystore caroot.keystore -storepass "$caroot_pw" \
    -alias root \
    -ext san=dns:intermediate \
    -keyalg RSA |
    keytool -importcert \
      -keystore caintermediate.keystore -storepass "$caim_pw" \
      -alias intermediate \
      -keyalg RSA

keytool -export \
  -keystore caroot.keystore -storepass "$caroot_pw" \
  -alias root |
  keytool -import \
    -keystore server.keystore -storepass "$endpoint_pw" \
    -alias root \
    -noprompt \
    -trustcacerts

keytool -genkeypair \
  -keystore server.keystore -storepass "$endpoint_pw" \
  -alias server \
  -dname "$base_dn,cn=server" \
  -keyalg RSA

keytool -certreq \
  -keystore server.keystore -storepass "$endpoint_pw" \
  -alias server \
  -keyalg RSA |
  keytool -gencert \
    -keystore caintermediate.keystore -storepass "$caim_pw" \
    -alias intermediate \
    -keyalg RSA |
    keytool -importcert \
      -keystore server.keystore -storepass "$endpoint_pw" \
      -alias server \
      -keyalg RSA \
      -noprompt \
      -trustcacerts

keytool -delete \
  -keystore server.keystore -storepass "$endpoint_pw" \
  -alias root

keytool -export \
  -keystore caroot.keystore -storepass "$caroot_pw" \
  -alias root |
  keytool -import \
    -keystore trust.keystore -storepass "$trust_pw" \
    -alias root \
    -noprompt

keytool -export \
  -keystore caintermediate.keystore -storepass "$caim_pw" \
  -alias intermediate |
  keytool -import \
    -keystore trust -storepass "$trust_pw" \
    -alias intermediate \
    -trustcacerts

keytool -list -v \
  -keystore trust.keystore -storepass "$trust_pw"

keytool -list -v \
  -keystore server.keystore -storepass "$endpoint_pw"
