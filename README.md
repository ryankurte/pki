# Bootstraping PKI with Yubikeys

Helper scripts to bootstrap an internal CA using cross signed roots on two Yubikey devices.

This requires a pair of Yubikey devices to store root certificates and keys, as well as an offline machine to generate the root keys and intermediate certificates. In future it may be possible to generate all keys on devices to aleviate this slightly.


## Status
Bootstrapping working on OSX, needs cross platform support, some features and a security review.

## Process

### Building the root CA

1. Generate a pair of root keys
2. Generate self signed root certificates
3. Generate CSRs for each root certificate
4. Cross sign root certificates
5. Load root keys onto yubikey devices
5. Load cross signed intermediate CAs onto yubikeys

### Building intermediate certificates

1. Generate intermediate key
2. Generate certificate and CSR
3. Load intermediate CA from attached yubikey
4. Sign CSR using attached yubikey

## Usage

1. `./build-roots.sh` to build roots and load onto yubikeys
2. add `work/roots.crt` to your allowed CAs
3. `./build-int.sh NAME` to build an intermediate CA with the provided name that can be validated against the above roots.

Output files will all be written to the `work/` directory.

### Dependencies

- OpenSSL
- OpenSC
- Yubico PIV tool
- engine_pks11.so

OSX: install with `brew install openssl engine_pkcs11 opensc yubico-piv-tool`.

## TODO

1. Move key generation and operations to yubikey, should be possible but may require libssl calls for self signed roots
2. Add build-int feature to build intermediate ca on another yubikey (instead of locally)
3. Add build-int feature to sign a provided certificate so keys don't have to leave the intermediate device
4. Could remove keys once generated
5. Support eliptic curve as well as RSA certificates
6. Optionally set management keys and prompt for pin/puk change
7. Discover paths or platform so this works on OSX or Linux

## Resources

- https://developers.yubico.com/yubico-piv-tool/
- https://developers.yubico.com/PIV/Guides/Certificate_authority.html
- https://github.com/OpenSC/OpenSC/wiki/SmartCardHSM

------

If you have any questions, comments, or suggestions, feel free to open an issue or a pull request.

