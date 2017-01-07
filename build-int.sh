#!/bin/bash 
# Generates an intermediate CA using the connected yubikey

NAME=$1
PIN=123456

KEYLEN=4096
HASH=sha256

# Output directory
DIR=work

# OpenSSL constants
OPENSSL_BIN=/usr/local/opt/openssl/bin/openssl
OPENSSL_ENGINE="engine dynamic -pre SO_PATH:/usr/local/lib/engines/engine_pkcs11.so -pre ID:pkcs11 \
    -pre LIST_ADD:1 -pre LOAD -pre MODULE_PATH:/usr/local/lib/opensc-pkcs11.so"

# Check input count
if [ "$#" -ne 1 ] && [ "$#" -ne 4 ]; then 
    echo "Usage: $0 NAME"
    echo "NAME - intermediate certificate name"
    exit
fi

# Exit on error
set -e

# Create working dir
mkdir -p work

echo "Generating new intermediate cert: $NAME"

echo "Fetching yubikey CA cert"
yubico-piv-tool -a read-cert -s 9c > work/yk-ca.crt
openssl x509 -in $DIR/yk-ca.crt -serial -noout | sed -e "s/serial=//g" > $DIR/yk-ca.srl

echo "Generating intermediate key"
openssl genrsa -out $DIR/$NAME.key $KEYLEN

echo "Generating intermediate CSR"
openssl req -new -out $DIR/$NAME.csr -key $DIR/$NAME.key

echo "Signing certificate"
echo "$OPENSSL_ENGINE
    x509 -engine pkcs11 -CAkeyform engine -CAkey slot_0-id_2 -$HASH -CA $DIR/yk-ca.crt -req \
    -passin pass:$PIN -in $DIR/$NAME.csr -out $DIR/$NAME.crt
    exit
    " | $OPENSSL_BIN

echo ""
echo "Created intermediate cert: $NAME"
