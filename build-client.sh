#!/bin/bash 
# Generates an client certificate from the provided client certificate
# This can use either a provided certificate + key or 

# Load constants
. ./common.sh

# Check input count
if [ "$#" -ne 2 ]; then 
    echo "Usage: $0 MODE FILE [CONFIG]"
    echo "MODE - local for local certificate, yubikey for yubikey based certificate"
    echo "FILE - client certificate file name"
    echo "[CONFIG] - config file to bootstrap csr"
    exit
fi

MODE=$1
FILE=$2

if [ "$MODE" != "local" ] && [ "$MODE" != "yubikey" ]; then
    echo "Unrecognised mode (expected local or yubikey)"
    exit
fi

echo "Generating new client cert: $FILE"

echo "Generating client key"
openssl genrsa -out $DIR/$FILE.key $KEYLEN

echo "Generating client CSR"
openssl req -new -out $DIR/$FILE.csr -key $DIR/$FILE.key

read -p "Insert intermediate yubikey and press enter to continue..."

echo "Fetching yubikey intermediate cert"
yk_fetch $DIR/yk-int.crt $DIR/yk-int.srl

echo "Signing client certificate"
yk_sign_client $DIR/yk-int.crt $DIR/$FILE.csr $DIR/$FILE.crt

echo "Attaching intermediate certificate"
cat $DIR/yk-int.crt >> $DIR/$FILE.crt

echo "Created client certificate: $FILE"

# Load cert and key in yubikey mode
if [ "$MODE" = "yubikey" ]; then
    read -p "Insert new client yubikey and press enter to continue..."

    yk_load $DIR/$FILE.crt $DIR/$FILE.key

    rm $DIR/$FILE.key
fi
