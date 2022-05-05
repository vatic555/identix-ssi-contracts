pragma ton-solidity >= 0.35.0;

library Errors {
    uint8 constant MessageSenderIsNotController = 200;
    uint8 constant MessageSenderIsNotIdxAuthority = 201;
    uint8 constant MissingOwnerPublicKeyOrAddressOrBothGiven = 202;
    uint8 constant MissingOwnerPublicKey = 203;
    uint8 constant AddressOrPubKeyIsNull = 204;
    uint8 constant ValueTooLow = 205;
    uint8 constant InvalidArgument = 206;
}