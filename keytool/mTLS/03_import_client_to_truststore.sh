#!/usr/bin/env bash
PATH=/opt/jdk-11.0.18+10/bin:$PATH
jmxserver_trust_pw=password4

keytool -importcert \
  -keystore jmxserver.truststore -storepass "$jmxserver_trust_pw" \
  -alias jmxclient \
  -file jmxclient.cer \
  -noprompt
