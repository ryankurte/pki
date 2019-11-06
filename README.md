# Bootstraping PKI with Yubikeys

Helper scripts to build and manage internal Certificate Authorities (CAs) with yubikey devices, because everybody needs a little bit of PKI, and we can definitely make it cheaper and easier to achieve.

This project is intended to be used as a template for the creation and management of certificate infrastructure, with CA information stored in git, and consists of a set of helper utilities to support the creation of root certificates, intermediate and end (client and certificate) Certificate Signing Requests (CSRs), as well as to load certificates and keys on to yubikeys and to use yubikeys to sign CSRs to create certificates.

This requires as many yubikeys as you would like to store certificates on, as well as an offline machine to generate the root keys and intermediate certificates. 
In future it may be possible to generate all keys on devices to aleviate this need for a trusted / airgapped machine.


## Introduction

### What is PKI?

PKI is Public Key Infrastructure, a method using cryptographic certificates to validate or authenticate services or devices. 
This works using a trust chain, whereby devices can trust a root Certificate Authority (CA), then any certificates issued by that authority can be validated against that root.


### Why would you need it?
This is commonly used for HTTPS/TLS on the web, where certificate authorities are distributed as part of your operating system or browser, allowing transparent validation and secure connections through the web.
Sometimes it is useful to have an internal certificate authority (or a few), for use between micro-services, or in manufacturing to ensure security with physical devices.

### Why would we want to use yubikeys?

TODO


## Status
Working on OSX, Linux, Windows seems [v cursed](https://github.com/ryankurte/pki/issues/9)


## Usage

First, create your own PKI git repository using this as a template, then use the following steps to create a Root / CA, Intermediate certificates, and Client or Server certificates.

Note that when deploying yubikeys you may wish to configure management and PIV pins to ensure that certificates are not mistakenly overwritten, and are only used by authorized parties. We recommend you read [this](https://developers.yubico.com/yubico-piv-tool/YubiKey_PIV_introduction.html) getting started guide for PIV on yubikeys before getting underway.

### Creating a new Certificate Authority (Root Certificate)

1. Run `mkdir CA_NAME` to create a new directory for your CA
2. Run `cp example-ca/config CA_NAME/config` to copy the example config to your new CA directory
3. Edit `CA_NAME/config` to configure your CA
4. Run `./scripts/new-ca.sh CA_NAME "Human Description"` to create the root certificate
5. Run `./scripts/yk-load CA_NAME CA_NAME` to load the root certificate onto a connected yubikey
6. Run `rm CA_NAME/CA_NAME.key` to remove CA key from the system
7. Run `git add CA_NAME/` to add your new CA to version control

### Creating a new Intermediate Certificate

1. Run `./scripts/new-int.sh CA_NAME INT_NAME "Human Description"` to create a new intermediate CSR under the provided CA
2. Run `./scripts/yk-sign-int.sh CA_NAME INT_NAME` to sign the intermediate CSR using the root yubikey
  - You will need to enter the device pin and press the button on the yubikey when the light flashes to authorize the signing
3. **Disconnect the attached root yubikey and replace it with a new intermediate yubikey**
4. Run `./scripts/yk-load CA_NAME INT_NAME` to load the CA onto a connected yubikey
5. Run `rm CA_NAME/INT_NAME.key` to remove intermediate key from the system
6. Run `git add CA_NAME/INT_NAME.*` to add your new intermediate to version control

Note that steps 4-6 can be elided if you need to do something else with your intermediate certificate

### Creating a new End Certificate

1. Run `./scripts/new-client.sh CA_NAME CLIENT_NAME` or `./scripts/new-server.sh CA_NAME SERVER_NAME` to create a new client or server cerficiate respectively
    - Note that server names are checked when making tls connections, so the server name must match the domain name
2. Run `./scripts/yk-sign-end.sh CA_NAME END_NAME` to sign the client or server CSR using an intermediate yubikey
  - You will need to enter the device pin and press the button on the yubikey when the light flashes to authorize the signing
3. Run `git add CA_NAME/END_NAME.crt` to add your new certificate to version control
4. Do whatever you choose with the created certificate



### Dependencies

- Git
- OpenSSL
- OpenSC
- [Yubico Manager](https://developers.yubico.com/yubikey-manager/)
- engine_pks11.so

OSX: install with `brew install openssl engine_pkcs11 opensc yubico-piv-tool`.
Linux: install with `sudo apt install openssl opensc-pkcs11 libengine-pkcs11-openssl`


## Resources

- https://developers.yubico.com/yubico-piv-tool/YubiKey_PIV_introduction.html
- https://developers.yubico.com/PIV/Guides/Certificate_authority.html
- https://github.com/OpenSC/OpenSC/wiki/SmartCardHSM
- https://www.owasp.org/index.php/Transport_Layer_Protection_Cheat_Sheet

------

If you have any questions, comments, or suggestions, feel free to open an issue or a pull request.

