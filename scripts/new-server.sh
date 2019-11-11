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

# Make server certificate dir
mkdir -p $DIR/server

# Generate a new server key
echo "Generating key: $DIR/server/$SERVER_NAME.key"
generate_key $DIR/server/$SERVER_NAME.key

# Copy (and edit!) the intermediate certificate configuration template
echo "Generating config: $DIR/server/$SERVER_NAME.conf"
configure_file templates/server.cfg.tmpl $DIR/server/$SERVER_NAME.conf "$SERVER_NAME"
	
# Generate new CSR
echo "Generating csr: $DIR/server/$SERVER_NAME.csr"
openssl req -new -config $DIR/server/$SERVER_NAME.conf -key $DIR/server/$SERVER_NAME.key -out $DIR/server/$SERVER_NAME.csr 

# All done!
echo "Generated CSR: $DIR/server/$SERVER_NAME.csr, this must now be signed"

