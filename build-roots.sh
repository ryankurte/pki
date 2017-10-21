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

fcfg --input=ca.conf.in --output=$DIR/root-a.conf --config=site.yml -v=FileName:root-a -v=Suffix:'ROOT A' -vPrivateKey:root-a -vPathLen:2 --quiet

build_selfsigned root-a

echo "Root B"
prepare_files root-b

fcfg --input=ca.conf.in --output=$DIR/root-b.conf --config=site.yml -v=FileName:root-b -v=Suffix:'ROOT B' -vPrivateKey:root-b -vPathLen:2 --quiet

build_selfsigned root-b


echo "Cross signing CA roots"

echo "Cross A"
prepare_files cross-a

fcfg --input=ca.conf.in --output=$DIR/cross-a.conf --config=site.yml -v=FileName:cross-a -v=Suffix:'CROSS ROOT A' -vPrivateKey:root-a -vPathLen:1 --quiet

build_and_sign root-b cross-a root-a

echo "Cross B"
prepare_files cross-b

fcfg --input=ca.conf.in --output=$DIR/cross-b.conf --config=site.yml -v=FileName:cross-b -v=Suffix:'CROSS ROOT B' -vPrivateKey:root-b -vPathLen:1 --quiet

build_and_sign root-a cross-b root-b

echo "Packaging ROOT CAs"
cat $DIR/root-a.crt > $DIR/roots.crt
cat $DIR/root-b.crt >> $DIR/roots.crt

echo "Completed root and cross CA generation"
echo "Load certificates and keys with ./load-roots.sh"

