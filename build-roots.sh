#!/bin/bash
# Generates a cross signed root CA and stores the generated CA files on yubikeys

# Load common components
. ./common.sh

ROOT_ARGS="-vIsCA:true -vUsages:keyCertSign,cRLSign -vPathLen:2 -vPrompt:no -vUseCRL:true"
CROSS_ARGS="-vIsCA:true -vUsages:keyCertSign,cRLSign -vPathLen:1 -vPrompt:no -vUseCRL:true"

echo "Generating Root Keys"
openssl genrsa -out $DIR/root-a.key ${KEYLEN}
openssl genrsa -out $DIR/root-b.key ${KEYLEN}

echo "Self signing root certificates"

echo "Building root certificate A"
prepare_files $DIR/root-a

fcfg --input=cert.conf.in --output=$DIR/root-a.conf --config=site.yml -v=FileName:root-a -v=Suffix:'ROOT A' \
    -vPrivateKey:root-a $ROOT_ARGS --quiet

build_selfsigned root-a

echo "Building root certificate B"
prepare_files $DIR/root-b

fcfg --input=cert.conf.in --output=$DIR/root-b.conf --config=site.yml -v=FileName:root-b -v=Suffix:'ROOT B' \
    -vPrivateKey:root-b $ROOT_ARGS --quiet

build_selfsigned root-b

echo "Cross signing CA roots"

echo "Building cross certificate A"
prepare_files $DIR/cross-a

fcfg --input=cert.conf.in --output=$DIR/cross-a.conf --config=site.yml -v=FileName:cross-a -v=Suffix:'CROSS ROOT A' \
    -vPrivateKey:root-a $CROSS_ARGS --quiet

build_and_sign root-b cross-a root-a

echo "Building cross certificate B"
prepare_files $DIR/cross-b

fcfg --input=cert.conf.in --output=$DIR/cross-b.conf --config=site.yml -v=FileName:cross-b -v=Suffix:'CROSS ROOT B' \
    -vPrivateKey:root-b $CROSS_ARGS --quiet

build_and_sign root-a cross-b root-b

echo "Packaging ROOT CAs"
cat $DIR/root-a.crt $DIR/root-b.crt $DIR/cross-a.crt $DIR/cross-b.crt > $DIR/roots.crt

echo "Completed root and cross CA generation"
echo "Load certificates and keys with ./load-roots.sh"

