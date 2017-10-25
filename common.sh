#!/bin/bash
# Constants for use across PKI helpers

PIN=123456

# 2048-bit maximum for yubikeys
KEYLEN=2048
HASH=sha512
SLOT=9c
CA_DAYS=365000

# Output directory
DIR=work

# Create working directory
mkdir -p $DIR

# Fail on errors
set -e

# OpenSSL config
# TODO: switch paths based on OS
OPENSSL_BIN=/usr/local/opt/openssl/bin/openssl
OPENSSL_ENGINE="engine dynamic -pre SO_PATH:/usr/local/lib/engines/engine_pkcs11.so -pre ID:pkcs11 \
    -pre LIST_ADD:1 -pre LOAD -pre MODULE_PATH:/usr/local/lib/opensc-pkcs11.so"


function build_selfsigned {
    openssl req -new -config $DIR/$1.conf -key $DIR/$1.key -out $DIR/$1.csr
    openssl ca -selfsign -days $CA_DAYS -config $DIR/$1.conf -in $DIR/$1.csr -out $DIR/$1.crt -batch
    openssl x509 -in $DIR/$1.crt -outform pem -out $DIR/$1.pem
}

function build_and_sign {
    echo "Building certificate with ca: $1 from config: $2 and key: $3"
    openssl req -new -config $DIR/$2.conf -key $DIR/$3.key -out $DIR/$2.csr
    openssl ca -days $CA_DAYS -config $DIR/$1.conf -in $DIR/$2.csr -out $DIR/$2.crt -batch
    openssl x509 -in $DIR/$2.crt -outform pem -out $DIR/$2.pem
}

function prepare_files {
    cp /dev/null $1.db
    cp /dev/null $1.db.attr
    echo 01 > $1.crt.srl
    echo 01 > $1.crl.srl
}

function yk_load {
    echo "Loading key $2 onto device"
    yubico-piv-tool -s ${SLOT} -a import-key -i $2 --touch-policy=always

    echo "Loading certificate $1 onto device"
    yubico-piv-tool -s ${SLOT} -a import-certificate -i $1

    echo "Device status:"
    yubico-piv-tool -a status
}

function yk_fetch {
    echo "Fetching yubikey CA cert"
    yubico-piv-tool -a read-cert -s 9c > $1
    openssl x509 -in $1 -serial -noout | sed -e "s/serial=//g" > $2
}


function yk_sign_ca {
    echo "Signing certificate request $2 with ca cert $1 and config $3, press yubikey button when light on device flashes"
    echo "$OPENSSL_ENGINE
        ca -batch -engine pkcs11 -keyform engine -keyfile slot_0-id_2 -cert $1 -config $3 \
        -passin pass:$PIN -in $2 -out $4
        exit
        " | $OPENSSL_BIN

    echo ""
}

function yk_sign_client {
    echo "Signing certificate request $2 with ca cert $1, press yubikey button when light on device flashes"
    echo "$OPENSSL_ENGINE
        x509 -engine pkcs11 -CAkeyform engine -CAkey slot_0-id_2 -$HASH -CA $1 -req \
        -passin pass:$PIN -extensions server_cert -in $2 -out $3
        exit
        " | $OPENSSL_BIN

    echo ""
}

function yk_revoke {
    echo "Revoking certificate $3 using ca $1 ($2), press yubikey button when light on device flashes"
    echo "$OPENSSL_ENGINE
        ca -batch -engine pkcs11 -keyform engine -keyfile slot_0-id_2 -cert $1 -config $2 \
        -passin pass:$PIN -revoke $3
        exit
        " | $OPENSSL_BIN

    echo ""
}

function yk_crl {
    echo "Generating CRL for CA $1 ($2), press yubikey button when light on device flashes"
    echo "$OPENSSL_ENGINE
        ca -batch -engine pkcs11 -keyform engine -keyfile slot_0-id_2 -cert $1 -config $2 \
        -passin pass:$PIN -gencrl -out $3
        exit
        " | $OPENSSL_BIN

    echo ""
}