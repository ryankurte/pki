#!/bin/bash
# Constants for use across PKI helpers

PIN=123456

KEYLEN=2048
HASH=sha256
SLOT=9c

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

function openssl_exec {
    echo "${OPENSSL_ENGINE}
    $1
    " | $OPENSSL_BIN
}

function openssl_selfsign {
    openssl_exec "req -engine pkcs11 -keyform engine -key slot_0-id_2 -passin pass:$PIN \
    -x509 -new -nodes -$HASH -days 36500 -verify -config $1 -out $2"
}

function openssl_csr {
    openssl_exec "req -engine pkcs11 -keyform engine -key slot_0-id_2 -passin pass:$PIN \
    -new -nodes -$HASH -verify -config $1 -out $2"
}

function openssl_sign {
    openssl_exec  "x509 -engine pkcs11 -CAkeyform engine -CAkey slot_0-id_2 -passin pass:$PIN \
    -CA $1 -req -$HASH -days 36500 -in $2 -out $3 -CAcreateserial"
}

# Load config from CLI
function get_config {
    read -r -p "Enter company name: " NAME
    read -r -p "Enter organisational unit: " OU
    read -r -p "Enter company URL: " URL
    read -r -p "Enter company admin email: " EMAIL
}

# Write config to a file for later use
function save_config {
    echo "NAME=$NAME"   >> $1
    echo "OU=$OU"       > $1
    echo "URL=$URL"     > $1
    echo "EMAIL=$EMAIL" > $1
}

# Process a config file
function build_root_config {
    sed "s/URL/${URL}/g;s/COMMON_NAME/${NAME}/g;s/TYPE/$1/g;s/EMAIL/${EMAIL}/g;s/COUNTRY/${COUNTRY}/g;s/OU/${OU}/g" $2 > $3
}
