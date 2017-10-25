#!/bin/bash

DIR=work
CONFIG="\'/CN=$TESTCN/OU=$TESTCA/O=$test.com/\'"

set -e

#./build-roots.sh "Fake Ltd." "Research" "fake.nz"
#./build-int.sh "yubikey" "test-int"
#./build-client.sh "yubikey" "test-client"

echo "Checking cross CAs"
openssl verify -CAfile work/root-a.crt work/cross-b.crt
openssl verify -CAfile work/root-b.crt work/cross-a.crt

openssl verify -CAfile work/roots.crt work/cross-a.crt
openssl verify -CAfile work/roots.crt work/cross-b.crt

echo "Checking intermediate generation"

openssl verify -verbose -CAfile $DIR/roots.crt $DIR/test-int.crt
openssl verify -verbose -CAfile $DIR/roots.crt $DIR/test-int2.crt

echo "Checking client generation"
openssl verify -verbose -CAfile $DIR/test-int2-chain.crt $DIR/test-client.crt

echo "Checking intermediate revocation"
#TODO:

echo "Checking client revocation"
#TODO:
