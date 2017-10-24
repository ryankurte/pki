#!/bin/bash 
# Builds and combines CRLs for the root CAs

# Load common components
. ./common.sh


# Check input count
if [ "$#" -ne 1 ]; then 
    echo "Usage: $0 CA"
    echo "CA - CA name for revocation (required for config loading)"
    exit
fi

CA=$1

read -p "Insert root yubikey and press enter to continue..."

echo "Fetching yubikey CA certificate"
yk_fetch $DIR/yk-ca.crt $DIR/yk-ca.srl

echo "Building CRL for CA $CA"
yk_crl $DIR/yk-ca.crt $DIR/$CA.conf $DIR/$CA.crl.pem

openssl crl -in $DIR/$CA.crl.pem -noout -text
