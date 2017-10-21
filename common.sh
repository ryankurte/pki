#!/bin/bash
# Constants for use across PKI helpers

PIN=123456

KEYLEN=2048
HASH=sha512
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

# Load config from CLI
function get_config {
    read -r -p "Enter company name: " NAME
    read -r -p "Enter organisational unit: " OU
    read -r -p "Enter company URL: " URL
    read -r -p "Enter company admin email: " EMAIL
    read -r -p "Enter CRL URL: " CRL
}

# Write config to a file for later use
function save_config {
    echo "$2_NAME=$NAME"   >> $1
    echo "$2_OU=$OU"       >> $1
    echo "$2_URL=$URL"     >> $1
    echo "$2_EMAIL=$EMAIL" >> $1
    echo "$2_CRL=$CRL"     >> $1
}

# Process a config file
function build_root_config {
    sed "s/URL/${URL}/g;s/COMMON_NAME/${NAME}/g;s/TYPE/$1/g;s/EMAIL/${EMAIL}/g;s/COUNTRY/${COUNTRY}/g;s/OU/${OU}/g;s|CRL|${CRL}|g;s/KEYFILE/${KEYFILE}/g" $2 > $3
}

function prepare_files {
    cp /dev/null $DIR/$1.db
    cp /dev/null $DIR/$1.db.attr
    echo 01 > ${DIR}/$1.crt.srl
    echo 01 > ${DIR}/$1.crl.srl

}