pragma ton-solidity >= 0.58.2;


interface IIdxDidDocument 
{
    // DID subject: The entity identified by a DID and described by a DID document. 
    // https://www.w3.org/TR/did-core/#dfn-did-subjects
    function getSubjectPubKey() external returns (uint256);

    // DID controller. An entity that has the capability to make changes to a DID document.
    // https://www.w3.org/TR/did-core/#dfn-did-controllers
    function getControllerAddress() external returns (address);

    // may change from custodial to non-custodial
    function changeController(address newController) external;
}