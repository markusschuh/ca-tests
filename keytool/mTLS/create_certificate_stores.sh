#!/usr/bin/env sh
./01_create_client_keypair.sh
./01_create_server_keypair.sh
./02_export_client_cert.sh
./02_export_server_cert.sh
./03_import_client_to_truststore.sh
./03_import_server_to_truststore.sh
