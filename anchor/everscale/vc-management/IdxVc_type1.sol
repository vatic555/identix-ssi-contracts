pragma ton-solidity >= 0.58.2;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "../libraries/Errors.sol";
import "../libraries/Aux.sol";
import "../interfaces/IIdxVc.sol";


struct ClaimGroup
{
    // HMAC-secured hashes
    uint64 hmacHigh_groupDid;
    uint64 hmacHigh_claimGroup;

    // 512 bit long signature of the full claimGroup hash
    uint256 signHighPart;
    uint256 signLowPart;
}

contract IdxVc_type1 is IIdxVc
{
    ClaimGroup[] static public claimGroups;
    uint256 public static issuerPubKey;
    uint16 public codeVer;

    constructor() internalMsg public
    {
        codeVer = 0x0010;
    }

    ////// Access //////
    
    modifier onlyController()
    {
        require(msg.pubkey() == issuerPubKey, Errors.MessageSenderIsNotController);
        _;
    }

    ////// General //////
    function transfer(address dest, uint128 value, bool bounce) 
        public pure onlyController
    {
        dest.transfer(value, bounce, 0);
    }    
}