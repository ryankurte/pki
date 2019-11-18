#!/bin/bash
# Load a certificate and key onto a yubikey

if [ "$#" -ne 2 ] && [ "$#" -ne 3 ]; then 
    echo "Usage: $0 DIR NAME [SLOT]"
    exit
fi

export DIR=$1
export NAME=$2
export SLOT=$3

if [ "$SLOT" == "" ]; then
export SLOT=9c
fi

set -e


# First, load the desired key into slot 9c (note you may wish to set a touch-policy and pin-policy of never for embedded devices)
echo "Loading key: $DIR/$NAME.key"
ykman piv import-key $SLOT $DIR/$NAME.key --touch-policy=always --pin-policy=ONCE


# Second, load the certificate file into slot 9c
echo "Loading cert: $DIR/$NAME.crt"
ykman piv import-certificate $SLOT $DIR/$NAME.crt
 

# Report new device status
echo "YubiKey status:"
ykman piv info
