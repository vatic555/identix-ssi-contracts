pragma ton-solidity >= 0.58.2;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "../libraries/Errors.sol";
import "../libraries/Aux.sol";
import "../interfaces/IIdxDidDocument.sol";

contract IdxDidDocument is IIdxDidDocument  
{   
    // IIdxController
    address public controller;
    uint256 static public subjectPubKey;
    // presumably IdxDidRegistry
    address static public idxAuthority;
    uint16 public codeVer;

    constructor(uint256 subjPubKey) public internalMsg
    {
        require(msg.sender.value != 0, Errors.AddressOrPubKeyIsNull);
        require(idxAuthority.value != 0, Errors.AddressOrPubKeyIsNull);
        require(subjPubKey != 0, Errors.AddressOrPubKeyIsNull);
        controller = msg.sender;
        subjectPubKey = subjPubKey;
        codeVer = 0x0010;
    }

    ////// IIdxDidDocument impl /////

    function getSubjectPubKey()
        override external returns (uint256)
    {
        return subjectPubKey;
    }

    function getControllerAddress() 
        override external returns (address)
    {
        return controller;
    }

    function changeController(address newController)
        override external onlyController
    {
        controller = newController;
    }
 
    ///// Upgrade //////
    function upgrade(TvmCell code, uint16 newCodeVer) 
        public onlyIdxAuthority
    {
        require (newCodeVer > codeVer);
        TvmBuilder state;
        state.store(controller);
        state.store(newCodeVer);

        tvm.accept();
        tvm.commit();
        tvm.setcode(code);
        tvm.setCurrentCode(code);
        onCodeUpgrade(state.toCell());
    }

    function onCodeUpgrade(TvmCell data) 
        private 
    {
        tvm.resetStorage();
        TvmSlice slice = data.toSlice();
        controller = slice.decode(address);
        codeVer = slice.decode(uint16);
    }

    ////// Access //////
    
    modifier onlyController()
    {
        require(msg.sender == controller, Errors.MessageSenderIsNotController);
        _;
    }

    modifier onlyIdxAuthority()
    {
        require(msg.sender == idxAuthority, Errors.MessageSenderIsNotIdxAuthority);
        _;
    }

    ////// General //////
    function transfer(address dest, uint128 value, bool bounce) 
        public pure onlyController
    {
        dest.transfer(value, bounce, 0);
    }
}
