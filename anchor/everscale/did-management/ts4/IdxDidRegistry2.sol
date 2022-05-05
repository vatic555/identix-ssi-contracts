pragma ton-solidity >= 0.58.2;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "../../libraries/Errors.sol";
import "../../libraries/Gas.sol";
import "../../libraries/Aux.sol";
import "../../interfaces/IIdxDidDocument.sol";
import "../IdxDidDocument.sol";

contract IdxSsoDidRegistry 
{
    TvmCell private _didDocTemplateCode;
    uint256 private _idxControllerPubKey;
    mapping (address => address[]) private _dids;
    uint16 public codeVer;

    constructor(TvmCell tplCode) 
        public externalMsg
    {
        require(msg.pubkey() != 0, Errors.AddressOrPubKeyIsNull);
        tvm.accept();
        _idxControllerPubKey = msg.pubkey();
        _didDocTemplateCode = tplCode;
        codeVer = 0xFF00;
    }

    ////// Document management //////

    function echo(string what) 
        external externalMsg responsible pure
        checkAccessAndAccept
        returns (string)
    {
        return what;
    }


    function issueDidDoc(uint256 subjectPubKey, uint256 salt, address didController) 
        external externalMsg responsible
        checkAccessAndAccept
        returns (address didDocAddr) 
    {
        // there can be many DIDs associated with a single controller
        // if provided salt is non-negative, it can be DID document content hash to make address computable
        TvmBuilder saltCell;
        saltCell.store(salt == 0 ? tx.timestamp : salt);
        TvmCell saltedCode = tvm.setCodeSalt(_didDocTemplateCode, saltCell.toCell());

		TvmCell stateInit = tvm.buildStateInit(
        {
            contr: IdxDidDocument,
            code: saltedCode,
            pubkey: tvm.pubkey(),
            varInit: 
            {
                subjectPubKey: subjectPubKey,
                idxAuthority: address(this)
            }
        });

		address addr = new IdxDidDocument
        {
            stateInit: stateInit, 
            value: Gas.DidDocInitialValue
        }
        (subjectPubKey);
        
        if (didController.value != 0)
            IIdxDidDocument(addr).changeController(didController);
        else
            didController = address(this);

        _dids[didController].push(addr);
        
        return (addr);
    }

    function getDidDocs(address controller)
        external view responsible
        returns (address[] docs) 
    {
        // external call from Identix owner
        if (msg.pubkey() != 0)
        {
            require(msg.pubkey() == _idxControllerPubKey, Errors.MessageSenderIsNotController);
            tvm.accept();
            if (controller.value == 0)
                controller = address(this);
        }
        // internal call
        else // if (msg.sender.value != 0)
        {
            require(msg.sender == controller, Errors.MessageSenderIsNotController);
        }

        address[] result;
        result = _dids[controller];
        return result;
    }

    ////// Templating //////
    function setTemplate(TvmCell code) 
        external externalMsg
        checkAccessAndAccept()
    {
        _didDocTemplateCode = code;
    }

    ///// Upgrade //////
    function upgrade(TvmCell code, uint16 nextVer) 
        public checkAccessAndAccept
    {
        require(nextVer > codeVer, 206);

        TvmBuilder state;
        state.store(_didDocTemplateCode);
        state.store(_idxControllerPubKey);
        state.store(_dids);
        state.store(nextVer);

        tvm.setcode(code);
        tvm.setCurrentCode(code);
        onCodeUpgrade(state.toCell());
    }

    function onCodeUpgrade(TvmCell data) 
        private 
    {
        tvm.resetStorage();
        TvmSlice slice = data.toSlice();
        _didDocTemplateCode = slice.decode(TvmCell);
        _idxControllerPubKey = slice.decode(uint256);
        _dids = slice.decode(mapping (address => address[]));
        codeVer = slice.decode(uint16);
    }

    ////// Access //////
    
    modifier checkAccessAndAccept() 
    {
        require(isController(), Errors.MessageSenderIsNotController);
        tvm.accept();
        _;
    }

    function isController()
        private view
        returns (bool)
    {
        return _idxControllerPubKey == msg.pubkey();
    }

    function changeController(uint256 newControllerPubKey)
        external
    {
        require(isController(), Errors.MessageSenderIsNotController);
        require(newControllerPubKey != 0, Errors.AddressOrPubKeyIsNull);
        tvm.accept();
        _idxControllerPubKey = newControllerPubKey;
    }

    ////// General //////
    function transfer(address dest, uint128 amount, bool bounce) 
        public pure
        checkAccessAndAccept()
    {
        dest.transfer(amount, bounce, 0);
    }
}