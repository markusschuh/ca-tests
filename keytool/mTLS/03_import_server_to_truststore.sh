#!/usr/bin/env bash
PATH=/opt/jdk-11.0.18+10/bin:$PATH
jmxclient_trust_pw=password3

keytool -importcert \
  -keystore jmxclient.truststore -storepass "$jmxclient_trust_pw" \
  -alias jmxserver \
  -file jmxserver.cer \
  -noprompt
