#!/bin/bash 
# Create a new server certificate
if [ "$#" -ne 2 ]; then 
    echo "Usage: $0 ROOT_NAME SERVER_NAME"
    exit
fi


# First, set the certificate base name and human names
export ROOT_NAME=$1
export SERVER_NAME=$2
export DIR=$1

set -e

# Load config
. $DIR/config

# Load helpers
. ./scripts/common.sh

# Generate a new server key
echo "Generating key: $DIR/$SERVER_NAME.key"
generate_key $DIR/$SERVER_NAME.key

# Copy (and edit!) the intermediate certificate configuration template
echo "Generating config: $DIR/$SERVER_NAME.conf"
configure_file templates/server.cfg.tmpl $DIR/$SERVER_NAME.conf "$SERVER_NAME"
	
# Generate new CSR
echo "Generating csr: $DIR/$SERVER_NAME.csr"
openssl req -new -config $DIR/$SERVER_NAME.conf -key $DIR/$SERVER_NAME.key -out $DIR/$SERVER_NAME.csr 

# All done!
echo "Generated CSR: $DIR/$SERVER_NAME.csr, this must now be signed"

