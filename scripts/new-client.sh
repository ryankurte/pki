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

# Generate a new intermediate key
echo "Generating key: $DIR/client/$CLIENT_NAME.key"
generate_key $DIR/client/$CLIENT_NAME.key

# Copy (and edit!) the intermediate certificate configuration template
echo "Generating config: $DIR/client/$CLIENT_NAME.conf"
configure_file templates/client.cfg.tmpl $DIR/client/$CLIENT_NAME.conf $CLIENT_NAME
	
# Generate new CSR
echo "Generating CSR: $DIR/client/$CLIENT_NAME.csr"
openssl req -new -config $DIR/client/$CLIENT_NAME.conf -key $DIR/client/$CLIENT_NAME.key -out $DIR/client/$CLIENT_NAME.csr 

# All done!
echo "Generated CSR: $DIR/$CLIENT_NAME.csr, this must now be signed"

