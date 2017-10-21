# Bootstraping PKI with Yubikeys

Helper scripts to bootstrap an internal Certificate Authority using cross signed roots on two Yubikey devices, because everybody needs a little bit of PKI, and we can definitely make it cheaper and easier to achieve.

This requires a pair of Yubikey devices to store root certificates and keys, as well as an offline machine to generate the root keys and intermediate certificates. In future it may be possible to generate all keys on devices to aleviate this need for a trusted / airgapped machine.

## Introduction

### What is PKI?
PKI is Public Key Infrastructure, a method using cryptographic certificates to validate or authenticate services or devices. 
This works using a trust chain, whereby devices can trust a root Certificate Authority (CA), then any certificates issued by that authority can be validated against that root.

### Why would you need it?
This is commonly used for HTTPS/TLS on the web, where certificate authorities are distributed as part of your operating system or browser, allowing transparent validation and secure connections through the web.
Sometimes it is useful to have an internal certificate authority, for use between micro-services, or in manufacturing to ensure security with physical devices.


## Status
Bootstrapping working on OSX, needs cross platform support (mainly pathing issues), some features and a security review.


## Process
First a root CA (self then cross signed) is built and loaded onto a pair of yubikeys. 
These roots can then be used to create (sign/revoke) intermediate certificates for use in infrastructure or on the production line. 
The intermediate certificates can finally be used to generate client certificates to be validated against the (self signed) root CAs.

### Building the root CA

1. Generate a pair of root keys
2. Generate self signed root certificates
3. Generate CSRs for each root certificate
4. Cross sign root certificates
5. Load root keys onto yubikey devices
5. Load cross signed root CAs onto yubikeys

The self signed root certificates are then used for certificate validation, and the cross signed roots for  issuance of intermediate certificates, thus allowing root A to revoke certificates issued by cross signed root B and vice versa.

### Building intermediate certificates

Intermediate certificates can be deployed to infrastructure that needs to be able to issue client certs.

1. Generate intermediate key
2. Generate certificate and CSR
3. Load intermediate CA from attached yubikey
4. Sign CSR using attached yubikey

### Creating client certificates

TODO

### Revoking client certificates


## Usage

1. `./build-roots.sh CN OU URL EMAIL` to build roots and load onto yubikeys
2. add `work/roots.crt` to your allowed CAs
3. `./build-int.sh TYPE FILE CN OU URL EMAIL` to build an intermediate CA with the provided name that can be validated against the above roots.

Something like:
```
./build-roots.sh "Totally Legit CA Inc." "Dept. of Small Fires" "legit-ca.org" "sup@legit-ca.org" "https://legit-ca.org/csr"

./build-int.sh yubikey int-01 "Totes Legit CA Inc Intermediate A" "Dept. of Small Fires" legit-ca.org sup@legit-ca.org
```

Note that if you intend to use revocation you will need to include a method for distributing revocations.

Output files will all be written to the `work/` directory.

### Dependencies

- OpenSSL
- OpenSC
- Yubico PIV tool
- engine_pks11.so

OSX: install with `brew install openssl engine_pkcs11 opensc yubico-piv-tool`.


## TODO

- [ ] Move key generation and operations to yubikey, should be possible but may require libssl calls for self signed roots
- [x] Add build-int feature to build intermediate ca on another yubikey (instead of locally)
- [ ] Add build-int feature to sign a provided certificate so keys don't have to leave the intermediate device
- [x] Could remove keys once generated
- [ ] Support eliptic curve as well as RSA certificates
- [ ] Optionally set management keys and prompt for pin/puk change
- [ ] Discover paths or platform so this works on OSX or Linux


## Resources

- https://developers.yubico.com/yubico-piv-tool/
- https://developers.yubico.com/PIV/Guides/Certificate_authority.html
- https://github.com/OpenSC/OpenSC/wiki/SmartCardHSM

------

If you have any questions, comments, or suggestions, feel free to open an issue or a pull request.

