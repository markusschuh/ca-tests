#!/usr/bin/env bash
PATH=/opt/jdk-11.0.18+10/bin:$PATH
jmxserver_pw=password2

keytool -exportcert \
  -keystore jmxserver.keystore -storepass "$jmxserver_pw" \
  -alias jmxserver \
  -file jmxserver.cer
