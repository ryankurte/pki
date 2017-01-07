#!/bin/bash

DIR=work
CONFIG="\'/CN=$TESTCN/OU=$TESTCA/O=$test.com/\'"

set -e

echo "Checking cross CAs"
openssl verify -verbose -CAfile ca2.crt ca1-cross.crt
openssl verify -verbose -CAfile ca1.crt ca2-cross.crt

echo "Checking intermediate generation"
openssl genrsa -out $DIR/test.key $KEYLEN
openssl req -new -out $DIR/test.csr -key $DIR/test.key -subject $CONFIG