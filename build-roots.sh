#!/bin/bash
# Generates a cross signed root CA and stores the generated CA files on yubikeys

# Load common components
. ./common.sh

# Fetch inputs depending on args
if [ "$#" -eq 4 ]; then 
    # Args provided, load directly
    NAME=$1
    OU=$2
    URL=$3
    EMAIL=$4
elif [ "$#" -eq 0 ]; then 
    # No args, ask user
    get_config
else
    # Print help
    echo "Usage: $0 [CN OU URL EMAIL]"
    echo "CN - Base Common Name for CA (ie. Foo Bar NZ Ltd.)"
    echo "OU - Organisational Unit for CA (ie. research)"
    echo "ORG - organisation url (ie foo.nz)"
    echo "EMAIL - certificate management email"
    exit
fi

echo "Generating CA for: $NAME URL: $URL EMAIL: $EMAIL COUNTRY: $COUNTRY"
echo ""
echo "IMPORTANT: yubikeys must be swapped a number of times during generation and cross signing"
echo "be sure to keep track of which yubikey is which"
echo "IMPORTANT: The yubikey may require physical confirmation for a number of steps"
echo "watch out for the flashing light on the device"

echo "Generating CA config files"
build_root_config "ROOT A" ca.conf.in $DIR/ca1.conf
build_root_config "ROOT B" ca.conf.in $DIR/ca2.conf
build_root_config "CROSS ROOT A" ca.conf.in $DIR/ca1-cross.conf
build_root_config "CROSS ROOT B" ca.conf.in $DIR/ca2-cross.conf

echo "Creating self signed roots"

echo "Insert first root yubikey"
read -p "Push enter to continue"

echo "Generating root key A on device"
yubico-piv-tool -s 9c -A RSA2048 -a generate --touch-policy=always

echo "Self signing root certificate A"
echo "Press yubikey button when light flashes"
echo "${OPENSSL_ENGINE}
    req -engine pkcs11 -keyform engine -key slot_0-id_2 -$HASH -passin pass:$PIN \
    -days 36500 -x509 -new -nodes -out $DIR/ca1.crt -config $DIR/ca1.conf
    exit
    " | $OPENSSL_BIN

echo "Loading root certificate A"
yubico-piv-tool -s ${SLOT} -a import-certificate -i $DIR/ca2.crt
openssl x509 -in $DIR/ca1.crt -serial -noout | sed -e "s/serial=//g" > $DIR/ca1.srl

echo "Generating CSR for root A cross signing"
echo "$OPENSSL_ENGINE
    req -engine pkcs11 -keyform engine -key slot_0-id_2 -$HASH -passin pass:$PIN \
    -new -nodes -config $DIR/ca1-cross.conf -out $DIR/ca1.csr
    exit
    " | $OPENSSL_BIN

echo "Insert second root yubikey"
read -p "Push enter to continue"

echo "Generating root key B on device"
yubico-piv-tool -s 9c -A RSA2048 -a generate --touch-policy=always

echo "Self signing root certificate B"
echo "Press yubikey button when light flashes"
echo "${OPENSSL_ENGINE}
    req -engine pkcs11 -keyform engine -key slot_0-id_2 -$HASH -passin pass:$PIN \
    -days 36500 -x509 -new -nodes -out $DIR/ca2.crt -config $DIR/ca2.conf
    exit
    " | $OPENSSL_BIN

echo "Loading root certificate B"
yubico-piv-tool -s ${SLOT} -a import-certificate -i $DIR/ca2.crt
openssl x509 -in $DIR/ca2.crt -serial -noout | sed -e "s/serial=//g" > $DIR/ca2.srl

echo "Generating CSR for root B cross signing"
echo "$OPENSSL_ENGINE
    req -engine pkcs11 -keyform engine -key slot_0-id_2 -$HASH -passin pass:$PIN \
    -new -nodes -config $DIR/ca2-cross.conf -out $DIR/ca2.csr
    exit
    " | $OPENSSL_BIN


echo "CA 1"
openssl x509 -noout -modulus -in work/ca1.crt | openssl md5
#openssl req -text -noout -verify -in work/ca1.csr
openssl req -noout -modulus -in work/ca1.csr | openssl md5

echo "CA 2"
openssl x509 -noout -modulus -in work/ca2.crt | openssl md5
#openssl req -text -noout -verify -in work/ca2.csr
openssl req -noout -modulus -in work/ca2.csr | openssl md5


echo "Cross signing CA roots"

echo "Insert first root yubikey"
read -p "Push enter to continue"

echo "Cross signing root certificate B"
echo "Press yubikey button when light on device flashes"
echo "$OPENSSL_ENGINE
    x509 -engine pkcs11 -CAkeyform engine -CAkey slot_0-id_2 -$HASH -CA $DIR/ca1.crt \
    -req -days 36500 -passin pass:$PIN -in $DIR/ca2.csr -out $DIR/ca2-cross.crt
    exit
    " | $OPENSSL_BIN

exit

echo "Insert second root yubikey"
read -p "Push enter to continue"

echo "Cross signing root certificate A"
echo "Press yubikey button when light on device flashes"
echo "$OPENSSL_ENGINE
    x509 -engine pkcs11 -CAkeyform engine -CAkey slot_0-id_2 -$HASH -CA $DIR/ca2.crt -CAserial $DIR/ca2.srl \
    -req -days 36500 -passin pass:$PIN -in $DIR/ca1.csr -out $DIR/ca1-cross.crt
    exit
    " | $OPENSSL_BIN


#echo "Packaging CAs"
#cat $DIR/ca1.crt > $DIR/roots.crt
#cat $DIR/ca2.crt >> $DIR/roots.crt
#
#
#echo "Loading cross signed certificates"
#
#echo "Insert first root yubikey"
#read -p "Push enter to continue"
#
#echo "Loading cross signed certificate A onto device"
#yubico-piv-tool -s ${SLOT} -a import-certificate -i $DIR/ca1-cross.crt
#
#echo "Yubikey one status:"
#yubico-piv-tool -a status
#
#echo "Insert second yubikey"
#read -p "Push enter to continue"
#
#echo "Loading cross signed certificate B onto device"
#yubico-piv-tool -s ${SLOT} -a import-certificate -i $DIR/ca2-cross.crt
#
#echo "Yubikey two status:"
#yubico-piv-tool -a status

