#!/bin/bash
# Create a new CA

if [ "$#" -ne 2 ]; then 
    echo "Usage: $0 ROOT_NAME \"Human Name\""
    exit
fi

# Setup variables
export ROOT_NAME=$1
export HUMAN_NAME=$2
export DIR=$ROOT_NAME

set -e

# Load config
. $DIR/config

# Load helpers
. ./scripts/common.sh

# Create a working directory and required files
touch $DIR/$ROOT_NAME.db
echo "01" > $DIR/$ROOT_NAME.srl

# Then, generate a root key
openssl genrsa -out $DIR/$ROOT_NAME.key 2048

# Copy (and edit!) the root certificate configuration template
configure_file templates/root.cfg.tmpl $DIR/$ROOT_NAME.conf "$HUMAN_NAME"

# Generate a Certificate Signing Request (CSR)
openssl req -new -config $DIR/$ROOT_NAME.conf -key $DIR/$ROOT_NAME.key -out $DIR/$ROOT_NAME.csr

# Self-sign the certificate request
openssl ca -selfsign -days 9999 -config $DIR/$ROOT_NAME.conf -in $DIR/$ROOT_NAME.csr -out $DIR/$ROOT_NAME.crt -batch

# Generate a PEM from the certificate file output
openssl x509 -in $DIR/$ROOT_NAME.crt -outform pem -out $DIR/$ROOT_NAME.pem

echo "Generated new CA: $DIR/$ROOT_NAME.crt"

