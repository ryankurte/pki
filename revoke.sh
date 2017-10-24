#!/bin/bash 
# Revokes a provided certificate using an attached yubikey

# Load common components
. ./common.sh

# Check input count
if [ "$#" -ne 2 ]; then 
    echo "Usage: $0 CA FILE"
    echo "CA - CA name for revocation (required for config loading)"
    echo "FILE - certificate to revoke"
    exit
fi

CA=$1
FILE=$2

read -p "Insert root yubikey and press enter to continue..."

echo "Fetching yubikey CA cert"
yk_fetch $DIR/yk-ca.crt $DIR/yk-ca.srl

echo "Revoking certificate"
yk_revoke $DIR/yk-ca.crt $DIR/$CA.conf $FILE

