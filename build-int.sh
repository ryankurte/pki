#!/bin/bash 
# Generates an intermediate CA using the connected yubikey
# This requires a root certificate yubikey to sign the new intermediate

# Load common components
. ./common.sh

# Check input count
if [ "$#" -ne 2 ]; then 
    echo "Usage: $0 MODE NAME"
    echo "MODE - local for local certificate, yubikey for yubikey based certificate"
    echo "NAME - intermediate certificate name"
    exit
fi

MODE=$1
NAME=$2

if [ "$MODE" != "local" ] && [ "$MODE" != "yubikey" ]; then
    echo "Unrecognised mode (expected local or yubikey)"
    exit
fi

# Load vars if vars.sh exists
if [ -f ./$DIR/vars.sh ]; then
    echo "Loading vars from: ./$DIR/vars.sh "
    . ./$DIR/vars.sh
fi

echo "Generating new intermediate cert: $NAME"

echo "Configuring intermediate cert from ./int.conf.in"
build_root_config "INTERMEDIATE" ./int.conf.in $DIR/int.conf

echo "Generating intermediate key"
openssl genrsa -out $DIR/$NAME.key $KEYLEN

echo "Generating intermediate CSR"
openssl req -new -sha256 -days 3650 -config $DIR/int.conf -key $DIR/$NAME.key -out $DIR/$NAME.csr 

echo "Insert root yubikey"
read -p "Push enter to continue"

echo "Fetching yubikey CA cert"
yubico-piv-tool -a read-cert -s 9c > work/yk-ca.crt
openssl x509 -in $DIR/yk-ca.crt -serial -noout | sed -e "s/serial=//g" > $DIR/yk-ca.srl

echo "Signing certificate"
echo "Press yubikey button when light on device flashes"
echo "$OPENSSL_ENGINE
    x509 -engine pkcs11 -CAkeyform engine -CAkey slot_0-id_2 -$HASH -CA $DIR/yk-ca.crt -req \
    -passin pass:$PIN -in $DIR/$NAME.csr -out $DIR/$NAME.crt
    exit
    " | $OPENSSL_BIN

echo ""
echo "Created intermediate cert: $NAME"

# Load cert and key in yubikey mode
if [ "$MODE" = "yubikey" ]; then
    echo "Loading intermediate onto yubikey"
    
    echo "Insert new intermediate yubikey"
    read -p "Push enter to continue"

    echo "Loading first key onto device"
    yubico-piv-tool -s ${SLOT} -a import-key -i $DIR/$NAME.key

    echo "Loading first cross signed certificate onto device"
    yubico-piv-tool -s ${SLOT} -a import-certificate -i $DIR/$NAME.crt

    echo "Yubikey status:"
    yubico-piv-tool -a status

    rm $DIR/$NAME.key
fi
