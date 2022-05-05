pragma ton-solidity >= 0.58.2;

library Aux
{
    function logCall(string fn) 
        internal
    {       
        tvm.log(format("{} {}, v:{} ton, msg.sender:{}, msg.pk:{}, tvm.pk:{}", 
            fn,
            msg.isExternal ? "external" : "internal", 
            msg.value / 1000000000,
            format("{:x}", msg.sender.value),
            format("{:x}", msg.pubkey()),
            format("{:x}", tvm.pubkey())
            ));
    }    

    function isPubKeyXorAddressNotEmpty(uint256 pk, address addr)
        internal
        returns (bool)
    {
        return (pk != 0 && addr.value == 0) || (pk == 0 && addr.value != 0);
    }
}