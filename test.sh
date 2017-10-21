#!/bin/bash

DIR=work
CONFIG="\'/CN=$TESTCN/OU=$TESTCA/O=$test.com/\'"

set -e

echo "Building root CAs"
./build-roots.sh "Fake Ltd." "Research" "fake.nz"

echo "Checking cross CAs"
openssl verify -CAfile work/root-a.crt work/cross-b.crt
openssl verify -CAfile work/root-b.crt work/cross-a.crt

echo "Checking intermediate generation"
./build-int.sh "yubikey" "test"
openssl verify -verbose -CAfile $DIR/roots.crt $DIR/test.crt

echo "Checking client generation"
#TODO:

echo "Checking intermediate revocation"
#TODO:

echo "Checking client revocation"
#TODO:
