#!/bin/bash
# Generates a cross signed root CA and stores the generated CA files on yubikeys

# Load common components
. ./common.sh

echo "Generating Root Keys"
openssl genrsa -out $DIR/root-a.key ${KEYLEN}
openssl genrsa -out $DIR/root-b.key ${KEYLEN}

echo "Self signing root certificates"

echo "Root A"
prepare_files root-a

fcfg --input=root.conf.in --output=$DIR/root-a.conf --config=site.yml -v=FileName:root-a -v=Suffix:'ROOT A' -vPrivateKey:root-a --quiet

openssl req -new -config $DIR/root-a.conf -key $DIR/root-a.key -out $DIR/root-a.csr

openssl ca -selfsign -days 365000 -config $DIR/root-a.conf -in $DIR/root-a.csr -out $DIR/root-a.crt

echo "Root B"
prepare_files root-b

fcfg --input=root.conf.in --output=$DIR/root-b.conf --config=site.yml -v=FileName:root-b -v=Suffix:'ROOT B' -vPrivateKey:root-b --quiet

openssl req -new -config $DIR/root-b.conf -key $DIR/root-b.key -out $DIR/root-b.csr

openssl ca -selfsign -days 365000 -config $DIR/root-b.conf -in $DIR/root-b.csr -out $DIR/root-b.crt


echo "Cross signing CA roots"

echo "Cross A"
prepare_files cross-a

fcfg --input=root.conf.in --output=$DIR/cross-a.conf --config=site.yml -v=FileName:cross-a -v=Suffix:'CROSS ROOT A' -vPrivateKey:root-a --quiet

openssl req -new -config $DIR/cross-a.conf -out $DIR/cross-a.csr -key $DIR/root-a.key 

openssl ca -days 400 -config $DIR/root-b.conf -in $DIR/cross-a.csr -out $DIR/cross-a.crt

echo "Cross B"
prepare_files cross-b

fcfg --input=root.conf.in --output=$DIR/cross-b.conf --config=site.yml -v=FileName:cross-b -v=Suffix:'CROSS ROOT B' -vPrivateKey:root-b --quiet

openssl req -new -config $DIR/cross-b.conf -out $DIR/cross-b.csr -key $DIR/root-b.key

openssl ca -days 400 -config $DIR/root-a.conf -in $DIR/cross-b.csr -out $DIR/cross-b.crt

echo "Packaging ROOT CAs"
cat $DIR/root-a.crt > $DIR/roots.crt
cat $DIR/root-b.crt >> $DIR/roots.crt

echo "Insert first yubikey"
#read -p "Push enter to continue"

echo "Loading first key onto device"
#yubico-piv-tool -s ${SLOT} -a import-key -i $DIR/ca1.key --touch-policy=always

echo "Loading first cross signed certificate onto device"
#yubico-piv-tool -s ${SLOT} -a import-certificate -i $DIR/ca1-cross.crt

echo "Yubikey one status:"
#yubico-piv-tool -a status

echo "Insert second yubikey"
#read -p "Push enter to continue"

echo "Loading second key onto device"
#yubico-piv-tool -s ${SLOT} -a import-key -i $DIR/ca2.key --touch-policy=always

echo "Loading second cross signed certificate onto device"
#yubico-piv-tool -s ${SLOT} -a import-certificate -i $DIR/ca2-cross.crt

echo "Yubikey two status:"
#yubico-piv-tool -a status

echo "Saving root configuration"
save_config $DIR/vars ROOT
