#!/bin/bash

DIR=work
CONFIG="\'/CN=$TESTCN/OU=$TESTCA/O=$test.com/\'"

set -e

echo "Checking cross CAs"
openssl verify -verbose -CAfile $DIR/ca2.crt $DIR/ca1-cross.crt
openssl verify -verbose -CAfile $DIR/ca1.crt $DIR/ca2-cross.crt

echo "Checking intermediate generation"
./build-int.sh test
openssl verify -verbose -CAfile $DIR/roots.crt $DIR/test.crt

echo "Checking intermediate revocation"

