pragma ton-solidity >= 0.58.2;

// https://github.com/tonlabs/TON-Solidity-Compiler/blob/master/API.md#tvmrawreserve
library MsgFlag 
{
    uint8 constant SenderPaysFee        = 1;
    uint8 constant IgnoreErrors         = 2;
    uint8 constant DestoryIfZero        = 32;
    uint8 constant RemainingGas         = 64;
    uint8 constant AllNotReserved       = 128;
}