#!/bin/bash

. common.sh

read -p "Insert first yubikey and press enter to continue"

yk_load $DIR/cross-a.crt $DIR/root-a.key

read -p "Insert second yubikey and press enter to continue"

yk_load $DIR/cross-b.crt $DIR/root-b.key
