#!/usr/bin/env bash
PATH=/opt/jdk-11.0.18+10/bin:$PATH
jmxserver_pw=password2
base_dn="dc=net,dc=example,ou=jmx"

keytool -genkeypair \
  -keystore jmxserver.keystore -storepass "$jmxserver_pw" \
  -alias jmxserver \
  -keyalg RSA -keysize 2048 \
  -dname "$base_dn,cn=jmxserver" \
  -validity 180
