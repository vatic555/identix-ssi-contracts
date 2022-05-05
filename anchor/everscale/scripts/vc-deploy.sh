#!/bin/bash
#set -x
. lib-contracts.sh

initial_balance=1000000000
network=Unknown
do_reset=0
idx_signer=idx
idx_pubkey=$(everdev s l | pcregrep -o1 '$idx_signer\s+([0-9a-z]+)')
issuer_pubkey=$(everdev s l | pcregrep -o1 'test122021\s+([0-9a-z]+)')
root=../vc-management
timeout=10

for a in $@
do
    if [[ "$network" = "main" ]]
    then
        wallet_addr=$a
    fi
    case $a in
        "se") network=se;;
        "dev") network=dev;;
        "main") network=main;;
        "reset") do_reset=1;;
    esac
done

if [[ "$network" = "se" ]] 
then
    giver_arg="-v $initial_balance"
    url_param="-u localhost"
    signer=$idx_signer
    timeout=0
    yell SE network
elif [[ "$network" = "dev" ]] 
then
    giver_arg="-v $initial_balance"
    url_param="--url eri01.net.everos.dev"
    signer=$idx_signer
    yell DEV network
elif [[ "$network" = "main" ]] 
then
    giver_arg=""
    url_param="-u eri01.main.everos.dev"
    signer=$idx_signer
    timeout=12
    yell MAIN network
else
    die $network is now valid for target network
fi

if [[ "$network" = "se" ]] && [[ "$do_reset" = "1" ]]; 
then 
    everdev se reset; 
fi

ddcode=$(decode_contract_code $root/IdxVc_type1.tvc)

if [[ "$network" = "main" ]] || [[ "$network" = "dev" ]];
then
    # calc the target addr
    caddr=$(tonos-cli genaddr --setkey ~/tonkeys/$signer $root/IdxVcFabric.tvc $root/IdxVcFabric.abi.json | grep_deploy_addr)
    assert_not_empty "$caddr" "Cannot generate addr"
    balance=$(get_contract_balance $caddr)
    if [[ -z "$balance" ]]; 
    then 
        balance="0" 
    fi
    if (( "$initial_balance" > "$balance" ));
    then
        #topping up the acc
        yell Balance of $(f_green $caddr) is low: $(f_red $balance), topping it up
        #success=$(tonos-cli $url_param multisig send --addr $(cat ~/tonkeys/cwallet_address) --dest $caddr --purpose "deploy" --sign ~/tonkeys/cwallet --value 1000000000 | grep Succeeded)
        success=$(everdev c r -n $network -s cwallet SafeMultisigWallet -a $(cat ~/tonkeys/cwallet_address) sendTransaction -i dest:$(echo -n $caddr | cut -d':' -f2),value:1000000000,bounce:false,flags:0,payload:\"\" | grep_success)
        yell "Waiting for the tx to complete..."
        sleep $timeout
        assert_not_empty "$success" "Cannot top up the acc: $caddr"
        sleep 6s
        balance=$(get_contract_balance $caddr)
        assert_not_empty "$balance" "Can't get balance. Probably the account is missing"
        [[ "$balance" -lt "900000000" ]] && die Low balance on the fabric: $balanace
    fi
    yell Fabric balance is $(f_green $balance)
fi

yell Deploying Identix VC fabric
fabric_addr=$(deploy_contract $root/IdxVcFabric $network $signer $giver_arg -i vcBaseImage:$ddcode)
yell Fabric deployed $(f_green $fabric_addr)

yell Testing VC issuance...
claim1='{ "hmacHigh_groupDid": "1", "hmacHigh_claimGroup": "20", "signHighPart": "3", "signLowPart": "4" }'
claims="[$claim1]"
yell "type $(f_bold 1) then the line below into the next two arg prompts:"
yell $(f_bold $claim1)
#vc_addr=$(everdev c r -n $network -s $signer $root/IdxVcFabric issueVc -i claims:${claims},issuerPubKey:0x$issuer_pubkey,answerId:0 | grep didDocAddr | cut -d'"' -f4)
vc_addr=$(everdev c r -n $network -s $signer $root/IdxVcFabric issueVc -i issuerPubKey:0x$issuer_pubkey,answerId:0 | grep vcAddr | cut -d'"' -f4)
assert_not_empty "$vc_addr" "issueVc failed"
yell VC deployed $(f_green $doc_addr)
yell "Waiting for the tx to complete..."
sleep $timeout
resultcontent=$(everdev c l -n $network -s $signer -a $vc_addr $root/IdxVc_type1 issuerPubKey | grep issuerPubKey | cut -d'"' -f4)
if [[ "0x$issuer_pubkey" != "$resultcontent" ]]
then
    die VC check test failed. Got: \"$resultcontent\". Exp: \"$issuer_pubkey\"
fi
yell $(f_green OK)