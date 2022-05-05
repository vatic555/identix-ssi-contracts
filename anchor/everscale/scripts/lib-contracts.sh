shopt -s expand_aliases

f_green() { echo $(tput setaf 2)$*$(tput sgr 0); }
f_red()   { echo "$(tput setaf 1)$*$(tput sgr 0)"; }
f_bold()   { echo "$(tput smso)$*$(tput rmso)"; }

yell() { echo $* >&2; }
die()  { yell $(f_red "$*"); exit 111; }
try()  { "$@" || die "cannot $*"; }

alias grep_deploy_addr="pcregrep -o1 'ddress.+?(0:[0-9a-z]+)' | cut -d$'\n' -f1"
alias grep_success="grep -e '\"success\": true'"
alias grep_output="pcregrep -M '(output.*(\n.*)+\}),'"

zero_addr=0000000000000000000000000000000000000000000000000000000000000000

assert_not_empty()
{
    local condition=$1
    local message=${2}
    if [[ -z "$condition" ]]; then die ${message}; fi
}

deploy_contract()
{
    local contract_file=$1
    assert_not_empty "$1" "deploy: contract file missing"
    local network=$2
    assert_not_empty "$2" "deploy: network missing"
    local signer=$3
    assert_not_empty "$3" "deploy: signer missing"
    local params="$4 $5 $6 $7 $8"

    everdev sol compile $contract_file.sol --output-dir $(dirname $contract_file)/
    [[ "$?" != "0" ]] && die "Error compiling $contract_file"
    yell Deploying $(f_bold $contract_file) at $network, signer $signer
    local caddr=$(everdev c d $contract_file.abi.json -n $network -s $signer $params | grep_deploy_addr)
    assert_not_empty $caddr "Cannot deploy $contract_file"
    echo $caddr
}

contract_address()
{
    local contract_file=$1
    assert_not_empty "$1" "deploy: contract file missing"
    local keys=$2
    assert_not_empty "$2" "deploy: keys missing"
    local path=$(dirname $contract_file)
    local result=$(tonos-cli genaddr --setkey $signer $path/$contract_file.tvc $path/$contract_file.abi.json | grep_deploy_addr)
    echo $result
}

get_contract_balance()
{
    local addr=$1
    assert_not_empty "$addr" "contract address missing"
    local result=$(everdev c i -n $network -a $addr | pcregrep -o1 '\((\d+) nano\)')
    echo $result
}

submitTransaction() {
    echo on
    local signer=$1
    local address=$2
    local contractName=$3
    local method=$4
    local param=$5
    local value=${6:-10000000} # 0.01
    yell tonos-cli body --abi "${contractName}.abi.json" "${method}" "${param}"
    body=$(tonos-cli body --abi "${contractName}.abi.json" "${method}" "${param}" | grep body | cut -d' ' -f3)
    yell $body
    yell =======
    input="dest:'${address}',value:${value},allBalance:false,bounce:true,payload:'$body'"
    yell "submitTransaction ${method} to ${contractName}"
    everdev contract run --signer "${signer}" SafeMultisigWallet submitTransaction --input "$input"
}

get_signer_pubkey()
{
    local signer=$1    
    assert_not_empty $signer "get_signer_pubkey: missing signer"
    local key=$(everdev s l | pcregrep -o1 "^$signer.+([a-z0-9]{64})")
    echo $key
}

decode_contract_code()
{
    local tvc_file=$1

    assert_not_empty $tvc_file "tvc file missing: $tvc_file"
    echo $(tonos-cli decode stateinit --tvc $tvc_file | pcregrep -o1 'code\": \"(.+?)\"')
}

decode_contract_data()
{
    local tvc_file=$1

    assert_not_empty $tvc_file "tvc file missing: $tvc_file"
    echo $(tonos-cli decode stateinit --tvc $tvc_file | pcregrep -o1 'data\": \"(.+?)\"')
}
