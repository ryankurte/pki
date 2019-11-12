#!/bin/bash
# Sign an client/server CSR using a yubikey

# Setup openssl path and use opensc-pkcs11 to interact with yubikey
OPENSSL_BIN=`which openssl`
#OPENSSL_ENGINE="engine dynamic -pre SO_PATH:/usr/local/lib/engines/engine_pkcs11.so -pre ID:pkcs11 \
#    -pre LIST_ADD:1 -pre LOAD -pre MODULE_PATH:/usr/local/lib/opensc-pkcs11.so"

if [ "$#" -ne 4 ] && [ "$#" -ne 5 ]; then 
    echo "Usage: $0 CA_NAME INT_NAME TYPE END_NAME [PIN]"
    echo "Where TYPE is client or server as appropriate"
    exit
fi

# Setup variables
export DIR=$1
export INT_NAME=$2
export TYPE=$3
export END_NAME=$4
export PIN=$5

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

## \"pkcs11:object=SIGN%20key;object-type=private;pin-value=$PIN\"

echo "Signing end certificate: $DIR/$TYPE/$END_NAME.crt"

set -e

# Run sign command
OPENSSL_CONF=$CONFIG openssl x509 -engine pkcs11 -CAkeyform engine -CAkey $SLOT $OPTIONS \
    -sha512 -CA $DIR/$INT_NAME.crt -req -in $DIR/$TYPE/$END_NAME.csr -days=$EXPIRY_DAYS \
    -out $DIR/$TYPE/$END_NAME.crt

echo "Signed end certificate: $DIR/$TYPE/$END_NAME.crt"
