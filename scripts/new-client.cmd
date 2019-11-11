
set ROOT_NAME=%1
set INT_NAME=%2
set CLIENT_NAME=%3

set OPENSSL_BIN="C:\Program Files\OpenSSL-Win64\bin\openssl.exe"
set KEY_LEN=2048
set EXPIRY_DAYS=9999

@echo off

if exist %ROOT_NAME%/%CLIENT_NAME%.key (
    echo "Using existing key: %ROOT_NAME%/%CLIENT_NAME%.key"
) else (
    echo "Generating new key: %ROOT_NAME%/%CLIENT_NAME%.key"
    %OPENSSL_BIN% genrsa -out %ROOT_NAME%/%CLIENT_NAME%.key %KEY_LEN%
)

if NOT EXIST %ROOT_NAME%/%CLIENT_NAME%.conf (
    echo "ERROR: Configuration %ROOT_NAME%/%CLIENT_NAME%.conf must be manually created"
    exit 2
)

echo "Generating CSR: %ROOT_NAME%/%CLIENT_NAME%.csr"
%OPENSSL_BIN% req -new -config %ROOT_NAME%/%CLIENT_NAME%.conf -key %ROOT_NAME%/%CLIENT_NAME%.key -out %ROOT_NAME%/%CLIENT_NAME%.csr 

echo "Signing CSR with Yubikey"
%OPENSSL_BIN%  x509 -engine pkcs11 -CAkeyform engine -CAkey slot_0-id_2 -sha512 -CA %ROOT_NAME%/%INT_NAME%.crt -req -in %ROOT_NAME%/%CLIENT_NAME%.csr -days=%EXPIRY_DAYS% -out %ROOT_NAME%/%CLIENT_NAME%.crt

