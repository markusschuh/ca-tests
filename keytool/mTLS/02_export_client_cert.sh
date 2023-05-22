#!/usr/bin/env bash
PATH=/opt/jdk-11.0.18+10/bin:$PATH
jmxclient_pw=password1

keytool -exportcert \
  -keystore jmxclient.keystore -storepass "$jmxclient_pw" \
  -alias jmxclient \
  -file jmxclient.cer
