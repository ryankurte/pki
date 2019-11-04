#!/bin/bash 
# Create a new client certificate
if [ "$#" -ne 2 ]; then 
    echo "Usage: $0 ROOT_NAME CLIENT_NAME"
    exit
fi

# First, set the certificate base name and human names
export ROOT_NAME=$1
export CLIENT_NAME=$2
export DIR=$1

set -e

# Load config
. $DIR/config

# Load helpers
. ./scripts/common.sh

echo "Generating key: $DIR/$CLIENT_NAME.key"
openssl genrsa -out $DIR/$CLIENT_NAME.key 2048

echo "Generating key: $DIR/$CLIENT_NAME.conf"

# Copy (and edit!) the intermediate certificate configuration template
configure_file templates/client.cfg.tmpl $DIR/$CLIENT_NAME.conf $CLIENT_NAME
	
# Generate new CSR
openssl req -new -config $DIR/$CLIENT_NAME.conf -key $DIR/$CLIENT_NAME.key -out $DIR/$CLIENT_NAME.csr 

# Create serial file
echo "01" > $DIR/$CLIENT_NAME.srl

echo "Generated CSR: $DIR/$CLIENT_NAME.csr, this must now be signed"

