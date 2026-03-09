#!/usr/bin/env bash

# https://docs.nomagic.com/spaces/TWCloud2024x/pages/286556280/Third-Party+Component+Compatibility

cassandra_basename=apache-cassandra
cassandra_version=4.1.10

export JAVA_HOME=/home/linuxbrew/.linuxbrew/opt/openjdk@11
PATH=${JAVA_HOME}/bin:$PATH

base_dn="dc=net,dc=example,ou=test"
keyalg=RSA
keysize=2048
validity=100

declare -A client_cert=(
  [dn]="$base_dn,cn=twc"
  [alias]=twc
  [keystore]=cassandra_client.p12
  [keystore_pw]=changeme
  [truststore]=client_connect.truststore
  [truststore_pw]=changeit
  [keyalg]="$keyalg"
  [keysize]="$keysize"
  [validity]="$validity"
)

declare -A server_cert=(
  [dn]="$base_dn,cn=cassandra"
  [alias]=cassandra
  [keystore]=client_connect.keystore
  [keystore_pw]=changeme
  [truststore]=cassandra_trust.p12
  [truststore_pw]=changeit
  [keyalg]="$keyalg"
  [keysize]="$keysize"
  [validity]="$validity"
)

### functions

check_command() {
  local command=$1
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "ERROR: command ´$command´ could not be found!"; exit 1
  fi
}

check_bash_version() {
  if [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
    echo "Error: Bash >= v4 is required, but this is: ${BASH_VERSINFO[0]}"; exit 1
  fi
}

##
## download_and_extract
##
download_and_extract() {
  local basename=$1 version=$2
  local fullname archive

  fullname="$basename-$version"
  archive="${fullname}-bin.tar.gz"
  curl -sS -LOR "https://dlcdn.apache.org/cassandra/${version}/${archive}"
  tar xf "${archive}"
}


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

check_command keytool
check_command Java
check_command curl
check_bash_version

download_and_extract "$cassandra_basename" "$cassandra_version"

python -m venv ~/.venv
~/.venv/bn/python -m pip install ruamel.yaml

cd "${cassandra_basename}-${cassandra_version}"

cd conf
mv cassandra.yaml cassandra.yaml.orig
sed -e 's/# truststore/truststore/' cassandra.yaml.orig > cassandra.yaml.temp1
~/.venv/bn/python <<EOT > cassandra.yaml.temp2
import sys
import ruamel.yaml
yaml=ruamel.yaml.YAML()
config=yaml.load(open("cassandra.yaml.temp1"))
config["client_encryption_options"]["enabled"]='true'
config["client_encryption_options"]["require_client_auth"]='true'
config["client_encryption_options"]["keystore"]='conf/client_connect.keystore'
config["client_encryption_options"]["keystore_password"]='changeme'
config["client_encryption_options"]["truststore"]='conf/client_connect.truststore'
config["client_encryption_options"]["truststore_password"]='changeit'
yaml.dump(config, sys.stdout)
EOT
sed -e "s/'true'/true/" cassandra.yaml.temp2 > cassandra.yaml
rm cassandra.yaml.temp[12]
cd ..

cd ..

generate_certificate client_cert
generate_certificate server_cert
generate_truststore  client_cert
generate_truststore  server_cert

mv client_connect.* "${cassandra_basename}-${cassandra_version}/conf"


cat <<EOT > SSLSocketClient.java
import java.io.*;
import javax.net.ssl.SSLSocketFactory;
import javax.net.ssl.SSLSocket;
public class SSLScocketClient {
  public static void main(String[] args) {
    String message = "Hello world";
    if (args.length != 2) {
      System.out.println("Usage: "+SSLScocketClient.class.getName()+" <host> <port>");
      System.exit(1);
    }
    String host = args[0];
    int    port = Integer.parseInt(args[1]);
    SSLSocketFactory sslsocketfactory = (SSLSocketFactory) SSLSocketFactory.getDefault();
    System.out.println("sending message: '" + message + "'");
    try {
      SSLSocket sslsocket = (SSLSocket) sslsocketfactory.createSocket(host, port);
      OutputStream os = new BufferedOutputStream(sslsocket.getOutputStream());
      os.write(message.getBytes());
      os.flush();
      InputStream is = new BufferedInputStream(sslsocket.getInputStream());
      byte[] data = new byte[2048];
      int len = is.read(data);
      System.out.printf("client received %d bytes: %s%n", len, new String(data, 0, len));
    } catch (Exception exception) {
      exception.printStackTrace();
    }
  }
}
EOT

check_access_args=(
  -Djavax.net.ssl.keyStore=../cassandra_client.p12 
  -Djavax.net.ssl.keyStorePassword=changeme 
  -Djavax.net.ssl.trustStore=../cassandra_trust.p12 
  -javax.net.ssl.trustStorePassword=changeit 
   SSLSocketClient.java 
   localhost 
   9042
)

java "${check_access_args[@]}"
# client received 113 bytes:...
# Invalid or unsupported protocol version (72); supported versions are (3/v3, 4/v4, 5/v5, 6/v6-beta)

### $ java SSLSocketClient.java localhost 9042
### javax.net.ssl.SSLHandshakeException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException:
###      unable to find valid certification path to requested target
###
### $ java -Djavax.net.ssl.trustStore=../cassandra_trust.p12 -Djavax.net.ssl.trustStorePassword=changeit SSLSocketClient.java localhost 9042
### javax.net.ssl.SSLHandshakeException: Received fatal alert: certificate_required


### openssl s_client -connect localhost:9042
###
### 80D0E9C94D740000:error:0A00045C:SSL routines:ssl3_read_bytes:tlsv13 alert certificate required:ssl/record/rec_layer_s3.c:918:SSL alert number 116
### 80D0E9C94D740000:error:0A000197:SSL routines:SSL_shutdown:shutdown while in init:ssl/ssl_lib.c:2804:
###
### openssl s_client -cert ../client.keystore -pass pass:changeme -connect localhost:9042 


## Secure connection with SSL between Cassandra and TWCloud
#esi.security {
#    cassandra {
#        enabled = true
#    	keystorePath = "<TWCloud installation folder>/configuration/cassandra_client.p12"
#    	keystoreType = "PKCS12"
#    	keystorePassword = "changeme"
#    	truststorePath = "<TWCloud installation folder>/configuration/cassandra_trust.p12"
#        truststoreType = "PKCS12"
#        truststorePassword = "changeit"
#    }
#}
