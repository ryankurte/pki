#!/bin/bash
# Generates a cross signed root CA and stores the generated CA files on yubikeys


KEYLEN=2048 # Key length
SLOT=9c     # Yubikey Certification slot
PIN=123456  # Yubikey pin
DIR=work

# Check inputs
if [ "$#" -ne 3 ]; then 
    echo "Usage: $0 CN OU ORG"
    echo "CN - Common Name for CA (ie. Foo Bar NZ Ltd.)"
    echo "OU - Organisational Unit for CA (ie. research)"
    echo "ORG - organisation url (ie foo.nz)"
    exit
fi

# Copy to working vars
CA_CN=$1
CA_OU=$2
CA_ORG=$3

# Fail on errors
set -e

echo "Generating CA for: $CA_CN OU: $CA_OU URL:$CA_ORG"
mkdir -p $DIR

echo "Generating CA config files"
sed "s/URL/${CA_ORG}/g;s/COMMON_NAME/${CA_CN}/g;s/ROOT/ROOT A/g" ca.conf.in > $DIR/ca1.conf
sed "s/URL/${CA_ORG}/g;s/COMMON_NAME/${CA_CN}/g;s/ROOT/ROOT B/g" ca.conf.in > $DIR/ca2.conf

echo "Generating Keys"
openssl genrsa -out $DIR/ca1.key ${KEYLEN}
openssl genrsa -out $DIR/ca2.key ${KEYLEN}

echo "Self signing root certificates"
openssl req -x509 -new -nodes -key $DIR/ca1.key -sha256 -days 36500 -out $DIR/ca1.crt -config $DIR/ca1.conf
openssl req -x509 -new -nodes -key $DIR/ca2.key -sha256 -days 36500 -out $DIR/ca2.crt -config $DIR/ca2.conf

echo "Generate cross signing CSRs"
openssl req -new -out $DIR/ca1.csr -key $DIR/ca1.key -config $DIR/ca1.conf
openssl req -new -out $DIR/ca2.csr -key $DIR/ca2.key -config $DIR/ca2.conf

echo "Cross signing CA roots"
openssl x509 -req -days 36500 -in $DIR/ca1.csr -out $DIR/ca1-cross.crt -CA $DIR/ca2.crt -CAkey $DIR/ca2.key -CAcreateserial
openssl x509 -req -days 36500 -in $DIR/ca2.csr -out $DIR/ca2-cross.crt -CA $DIR/ca1.crt -CAkey $DIR/ca1.key -CAcreateserial

echo "Packaging CAs"
cat $DIR/ca1.crt > $DIR/roots.crt
cat $DIR/ca2.crt >> $DIR/roots.crt

echo "Insert first yubikey"
read -p "Push enter to continue"

echo "Loading first key onto device"
yubico-piv-tool -s ${SLOT} -a import-key -i $DIR/ca1.key

echo "Loading first cross signed certificate onto device"
yubico-piv-tool -s ${SLOT} -a import-certificate -i $DIR/ca1-cross.crt

echo "Yubikey one status:"
yubico-piv-tool -a status

echo "Insert second yubikey"
read -p "Push enter to continue"

echo "Loading second key onto device"
yubico-piv-tool -s ${SLOT} -a import-key -i $DIR/ca2.key

echo "Loading second cross signed certificate onto device"
yubico-piv-tool -s ${SLOT} -a import-certificate -i $DIR/ca2-cross.crt

echo "Yubikey two status:"
yubico-piv-tool -a status

