#!/usr/bin/env bash
PATH=/opt/jdk-11.0.18+10/bin:$PATH
jmxclient_pw=password1
base_dn="dc=net,dc=example,ou=jmx"

keytool -genkeypair \
  -keystore jmxclient.keystore -storepass "$jmxclient_pw" \
  -alias jmxclient \
  -keyalg RSA -keysize 2048 \
  -dname "$basedn,cn=jmxclient" \
  -validity 180
