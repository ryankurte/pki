#!/bin/bash
# A script to bootstrap PKI using a pair of Yubikeys
# Resources:
# - https://developers.yubico.com/yubico-piv-tool/
# - https://developers.yubico.com/PIV/Guides/Certificate_authority.html

CA_CN="foo ltd."
CA_OU="bar group"
CA_ORG="foobar.com"

ALGO=ECCP256
KEYLEN=2048
SLOT=9c # Certification slot

CONFIG="\'/CN=${CA_CN}/OU=${CA_OU}/O=${CA_ORG}/\'"

echo "Generating CA config files"
sed "s/URL/${CA_ORG}/g;s/COMMON_NAME/${CA_CN}/g;s/ROOT/ROOT A/g" ca.conf.in > ca1.conf
sed "s/URL/${CA_ORG}/g;s/COMMON_NAME/${CA_CN}/g;s/ROOT/ROOT B/g" ca.conf.in > ca2.conf

echo "Insert first yubikey"

# Generate key
#openssl genrsa -out ca1.key ${KEYLEN}

# Load key onto device
#yubico-piv-tool -s ${SLOT} -a import-key -i ca1.key

# Generate signature request
echo Generating CA1 signature request
openssl req -x509 -new -nodes -key ca1.key -sha256 -days 36500 -out ca1.crt -config ca1.conf

# Loading cert onto device
yubico-piv-tool -s ${SLOT} -a import-certificate -i ca1.crt

# On device generation is going to require an app using openssl to generate unsigned signature 
# requests for passing to the yubikey for signing.
# Generate key on device
#yubico-piv-tool -s ${SLOT} -A ${ALGO} -a generate #> pk1.txt

# Generate signing request
#echo yubico-piv-tool -s ${SLOT} -S $CONFIG -P 123456 \
#  -a verify -a request

# Generate self signed cert
#echo yubico-piv-tool -s ${SLOT} -S $CONFIG -P 123456 \
#  -a verify -a selfsign


