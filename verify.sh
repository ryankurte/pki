#!/bin/bash

. ./common.sh

openssl verify -verbose -CAfile $DIR/roots.crt $1