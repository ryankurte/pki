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
echo "IMPORTANT: The yubikey may require physical confirmation during a number of steps"
echo "watch out for the flashing light on the device"

echo "Generating CA config files"
build_root_config "ROOT A" ca.conf.in $DIR/ca1-root.conf
build_root_config "ROOT B" ca.conf.in $DIR/ca2-root.conf
build_root_config "CROSS ROOT A" ca.conf.in $DIR/ca1-cross.conf
build_root_config "CROSS ROOT B" ca.conf.in $DIR/ca2-cross.conf

echo "Creating self signed roots"

printf "\n**************************\n"
echo "Insert first root yubikey"
read -p "Push enter to continue"

echo "Generating root key A on device"
yubico-piv-tool -s ${SLOT} -A RSA2048 -a generate -o $DIR/ca1-root.pem --touch-policy=never
yubico-piv-tool -s ${SLOT} -S '/CN=fake/OU=fake/O=fake.com/' -P ${PIN} -i ${DIR}/ca1-root.pem -a verify -a selfsign
yubico-piv-tool -a status

#$OPENSSL_BIN genrsa -out $DIR/ca1.key ${KEYLEN}
#yubico-piv-tool -s ${SLOT} -a import-key -i $DIR/ca1.key 

echo "Self signing root certificate A"
echo "Press yubikey button when light flashes"
openssl_selfsign $DIR/ca1-root.conf $DIR/ca1-root.crt

echo "Loading root certificate A"
yubico-piv-tool -s ${SLOT} -a import-certificate -i $DIR/ca1-root.crt
$OPENSSL_BIN x509 -in $DIR/ca1-root.crt -serial -noout | sed -e "s/serial=//g" > $DIR/ca1-root.srl

echo "Generating CSR for root A cross signing"
openssl_csr $DIR/ca1-cross.conf $DIR/ca1-cross.csr

#printf "\n**************************\n"
#echo "Insert second root yubikey"
#read -p "Push enter to continue"
#
#echo "Generating root key B on device"
#yubico-piv-tool -s 9c -A RSA2048 -a generate -o $DIR/ca2-root.pem --touch-policy=never
#yubico-piv-tool -s ${SLOT} -S '/CN=fake/OU=fake/O=fake.com/' -P ${PIN} -a verify -a selfsign
##$OPENSSL_BIN genrsa -out $DIR/ca2.key ${KEYLEN}
##yubico-piv-tool -s ${SLOT} -a import-key -i $DIR/ca2.key 
#
#echo "Self signing root certificate B"
#echo "Press yubikey button when light flashes"
#openssl_selfsign $DIR/ca2-root.conf $DIR/ca2-root.crt
#
#echo "Loading root certificate B"
#yubico-piv-tool -s ${SLOT} -a import-certificate -i $DIR/ca2-root.crt
#$OPENSSL_BIN x509 -in $DIR/ca2-root.crt -serial -noout | sed -e "s/serial=//g" > $DIR/ca2-root.srl
#
#echo "Generating CSR for root B cross signing"
#openssl_csr $DIR/ca2-cross.conf $DIR/ca2-cross.csr

echo "CA 1"
$OPENSSL_BIN x509 -noout -modulus -in work/ca1-root.crt | $OPENSSL_BIN md5
$OPENSSL_BIN req -noout -modulus -in work/ca1-cross.csr | $OPENSSL_BIN md5

# Get key modulus
echo "Public key information"
openssl rsa -pubin -inform PEM -text -noout -in work/ca1-root.pem

echo "Cert key information"
$OPENSSL_BIN x509 -text -noout -in work/ca1-root.crt

echo "CSR key information"
$OPENSSL_BIN req -text -noout -verify -in work/ca1-cross.csr

exit

echo "CA 2"
$OPENSSL_BIN x509 -noout -modulus -in work/ca2-root.crt | $OPENSSL_BIN md5
$OPENSSL_BIN req -noout -modulus -in work/ca2-cross.csr | $OPENSSL_BIN md5

$OPENSSL_BIN x509 -text -noout -in work/ca1-root.crt
$OPENSSL_BIN req -text -noout -verify -in work/ca2-cross.csr



echo "Cross signing CA roots"

printf "\n**************************\n"
echo "Insert first root yubikey"
read -p "Push enter to continue"

echo "Cross signing root certificate B"
echo "Press yubikey button when light on device flashes"
openssl_sign $DIR/ca1-root.crt $DIR/ca2-cross.csr $DIR/ca2-cross.crt

printf "\n**************************\n"
echo "Insert second root yubikey"
read -p "Push enter to continue"

echo "Cross signing root certificate A"
echo "Press yubikey button when light on device flashes"
openssl_sign $DIR/ca2-root.crt $DIR/ca1-cross.csr $DIR/ca1-cross.crt


echo "Packaging CAs"
cat $DIR/ca1-root.crt > $DIR/roots.crt
cat $DIR/ca2-root.crt >> $DIR/roots.crt


echo "Loading cross signed certificates"

printf "\n**************************\n"
echo "Insert first root yubikey"
read -p "Push enter to continue"

echo "Loading cross signed certificate A onto device"
yubico-piv-tool -s ${SLOT} -a import-certificate -i $DIR/ca1-cross.crt

echo "Yubikey one status:"
yubico-piv-tool -a status

printf "\n**************************\n"
echo "Insert second yubikey"
read -p "Push enter to continue"

echo "Loading cross signed certificate B onto device"
yubico-piv-tool -s ${SLOT} -a import-certificate -i $DIR/ca2-cross.crt

echo "Yubikey two status:"
yubico-piv-tool -a status


echo "CA bootstrapping complete"
