#!/bin/bash
# Sign an intermediate CSR using a yubikey

# Setup openssl path and use opensc-pkcs11 to interact with yubikey
OPENSSL_BIN=`which openssl`
#OPENSSL_ENGINE="engine dynamic -pre SO_PATH:/usr/local/lib/engines/engine_pkcs11.so -pre ID:pkcs11 \
#    -pre LIST_ADD:1 -pre LOAD -pre MODULE_PATH:/usr/local/lib/opensc-pkcs11.so"

if [ "$#" -ne 2 ] && [ "$#" -ne 3]; then 
    echo "Usage: $0 ROOT_NAME INT_NAME [PIN]"
    exit
fi

# Setup variables
export ROOT_NAME=$1
export INT_NAME=$2
export PIN=$3
export DIR=$ROOT_NAME

set -e


# Load config
. $DIR/config

# Load helpers
. ./scripts/common.sh


if [[ "$OSTYPE" == "linux-gnu" ]]; then
    CONFIG="scripts/engine-nix.conf"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    CONFIG="scripts/engine-osx.conf"
fi

if [[ "$PIN" != "" ]]; then 
    OPTIONS="-passin pass:$PIN"
else
    OPTIONS=""
fi

echo "Signing intermediate certificate: $DIR/$INT_NAME.crt with $DIR/$ROOT_NAME.crt"

# Run sign command
OPENSSL_CONF=$CONFIG openssl x509 -engine pkcs11 -CAkeyform engine -CAkey $SLOT $OPTIONS \
    -sha512 -CA $DIR/$ROOT_NAME.crt -req -extensions server_cert -days=$EXPIRY_DAYS \
    -in $DIR/$INT_NAME.csr -out $DIR/$INT_NAME.crt

echo "Signed $DIR/$INT_NAME.crt"
