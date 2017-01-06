#!/bin/bash
# A script to bootstrap PKI using a pair of Yubikeys
# Resources:
# - https://developers.yubico.com/yubico-piv-tool/
# - https://developers.yubico.com/PIV/Guides/Certificate_authority.html

# Company Name ie. Foo NZ Ltd.
CA_CN="foo ltd."
# Organisational Unit ie. Research and Development
CA_OU="R&D"
# Organisation name ie. foo.nz
CA_ORG="foobar.com"

KEYLEN=2048 # Key length
SLOT=9c     # Yubikey Certification slot


CONFIG="\'/CN=${CA_CN}/OU=${CA_OU}/O=${CA_ORG}/\'"

set -e

echo "Generating CA config files"
sed "s/URL/${CA_ORG}/g;s/COMMON_NAME/${CA_CN}/g;s/ROOT/ROOT A/g" ca.conf.in > ca1.conf
sed "s/URL/${CA_ORG}/g;s/COMMON_NAME/${CA_CN}/g;s/ROOT/ROOT B/g" ca.conf.in > ca2.conf

echo "Generating Keys"
openssl genrsa -out ca1.key ${KEYLEN}
openssl genrsa -out ca2.key ${KEYLEN}

echo "Self signing root certificates"
openssl req -x509 -new -nodes -key ca1.key -sha256 -days 36500 -out ca1.crt -config ca1.conf
openssl req -x509 -new -nodes -key ca2.key -sha256 -days 36500 -out ca2.crt -config ca2.conf

echo "Generate cross signing CSRs"
openssl req -new -out ca1.csr -key ca1.key -config ca1.conf
openssl req -new -out ca2.csr -key ca2.key -config ca2.conf

echo "Cross signing CA roots"
openssl x509 -req -days 36500 -in ca1.csr -out ca1-cross.crt -CA ca2.crt -CAkey ca2.key -CAcreateserial
openssl x509 -req -days 36500 -in ca2.csr -out ca2-cross.crt -CA ca1.crt -CAkey ca1.key -CAcreateserial

echo "Insert first yubikey"
read -p "Push enter to continue"

echo "Loading first key onto device"
yubico-piv-tool -s ${SLOT} -a import-key -i ca1.key

echo "Loading first cross signed certificate onto device"
yubico-piv-tool -s ${SLOT} -a import-certificate -i ca1-cross.crt

echo "Yubikey one status:"
yubico-piv-tool -a status

echo "Insert second yubikey"
read -p "Push enter to continue"

echo "Loading second key onto device"
yubico-piv-tool -s ${SLOT} -a import-key -i ca2.key

echo "Loading second cross signed certificate onto device"
yubico-piv-tool -s ${SLOT} -a import-certificate -i ca2-cross.crt

echo "Yubikey two status:"
yubico-piv-tool -a status

