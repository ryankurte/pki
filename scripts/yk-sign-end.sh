#!/bin/bash
# Sign an client/server CSR using a yubikey

# Setup openssl path and use opensc-pkcs11 to interact with yubikey
OPENSSL_BIN=`which openssl`
#OPENSSL_ENGINE="engine dynamic -pre SO_PATH:/usr/local/lib/engines/engine_pkcs11.so -pre ID:pkcs11 \
#    -pre LIST_ADD:1 -pre LOAD -pre MODULE_PATH:/usr/local/lib/opensc-pkcs11.so"

if [ "$#" -ne 3 ] && [ "$#" -ne 4 ]; then 
    echo "Usage: $0 DIR INT_NAME END_NAME"
    exit
fi

# Setup variables
export DIR=$1
export INT_NAME=$2
export END_NAME=$3

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

echo "Signing end certificate: $DIR/$END_NAME.crt"

set -e

# Run sign command
OPENSSL_CONF=$CONFIG openssl x509 -engine pkcs11 -CAkeyform engine -CAkey slot_0-id_2 \
    -sha512 -CA $DIR/$INT_NAME.crt -req -in $DIR/$END_NAME.csr -days=$EXPIRY_DAYS \
    -out $DIR/$END_NAME.crt

echo "Signed end certificate: $DIR/$END_NAME.crt"
