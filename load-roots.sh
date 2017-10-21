#!/bin/bash

. common.sh

echo "Insert first yubikey"
read -p "Push enter to continue"

echo "Loading first key onto device"
yubico-piv-tool -s ${SLOT} -a import-key -i $DIR/root-a.key --touch-policy=always

echo "Loading first cross signed certificate onto device"
yubico-piv-tool -s ${SLOT} -a import-certificate -i $DIR/cross-a.crt

echo "Yubikey one status:"
yubico-piv-tool -a status

echo "Insert second yubikey"
read -p "Push enter to continue"

echo "Loading second key onto device"
yubico-piv-tool -s ${SLOT} -a import-key -i $DIR/root-b.key --touch-policy=always

echo "Loading second cross signed certificate onto device"
yubico-piv-tool -s ${SLOT} -a import-certificate -i $DIR/cross-b.crt

echo "Yubikey two status:"
yubico-piv-tool -a status
