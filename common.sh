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

    openssl ca -selfsign -days $CA_DAYS -config $DIR/$1.conf -in $DIR/$1.csr -out $DIR/$1.crt
}

function build_and_sign {
    openssl req -new -config $DIR/$2.conf -out $DIR/$2.csr -key $DIR/$3.key

    openssl ca -days $CA_DAYS -config $DIR/$1.conf -in $DIR/$2.csr -out $DIR/$2.crt
}

function prepare_files {
    cp /dev/null $DIR/$1.db
    cp /dev/null $DIR/$1.db.attr
    echo 01 > ${DIR}/$1.crt.srl
    echo 01 > ${DIR}/$1.crl.srl

}