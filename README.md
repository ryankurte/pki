# Bootstraping PKI with Yubikeys

Helper scripts to bootstrap an internal CA using two cross signed roots on Yubikey devices.

This requires a pair of Yubikey devices to store root certificates and keys on.

## Usage

1. `./build-roots.sh` to build roots and load onto yubikeys
2. `./build-int.sh NAME` to build an intermediate CA with the provided name

### Dependencies

- OpenSSL
- OpenSC
- Yubico PIV tool
- engine_pks11.so

## TODO

1. Move key generation and operations to yubikey, should be possible but may require libssl calls
2. Add build-int feature to build intermediate ca on another yubikey (instead of locally)
3. Add build-int feature to sign a provided certificate so keys don't have to leave the intermediate device

