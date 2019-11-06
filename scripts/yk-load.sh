#!/bin/bash
# Load a certificate and key onto a yubikey

if [ "$#" -ne 2 ]; then 
    echo "Usage: $0 DIR NAME"
    exit
fi

export DIR=$1
export NAME=$2

set -e


# First, load the desired key into slot 9c (note you may wish to set a touch-policy and pin-policy of never for embedded devices)
echo "Loading key: $DIR/$NAME.key"
ykman piv import-key 9c $DIR/$NAME.key --touch-policy=always --pin-policy=ONCE


# Second, load the certificate file into slot 9c
echo "Loading cert: $DIR/$NAME.crt"
ykman piv import-certificate 9c $DIR/$NAME.crt
 

# Report new device status
echo "YubiKey status:"
ykman piv info
