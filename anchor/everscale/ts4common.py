from collections import namedtuple
from sys import flags
import urllib.request as ur
import os 
import tonos_ts4.ts4 as ts4
from tonos_ts4.address import Address
from tonos_ts4.global_functions import zero_addr

eq = ts4.eq
ever = ts4.GRAM

class DidContractError:
    MessageSenderIsNotController = 200
    MessageSenderIsNeitherOwnerNorAuthority = 201
    MissingOwnerPublicKeyOrAddressOrBothGiven = 202
    MissingOwnerPublicKey = 203
    AddressOrPubKeyIsNull = 204
    ValueTooLow = 205

KeyPair = namedtuple('KeyPair', 'private public')

# region Setup
# Initialize TS4 by specifying where the artifacts of the used contracts are located
# verbose: toggle to print additional execution info
ts4.init('../', verbose = False)


def check_method_params(abi, method, params):
    assert isinstance(abi, ts4.Abi)

    if method == '.data':
        inputs = abi.json['data']
    else:
        func = abi.find_abi_method(method)
        if func is None:
            raise Exception("Unknown method name '{}'".format(method))
        inputs = func['inputs']
    res = {}
    for param in inputs:
        pname = param['name']
        if pname not in params:
            # THIS IS WHAY THIS WORKABOUTN ABOUT
            if pname == 'answerId':
                params['answerId'] = 0
            else:
            # ENDOF WORKAROUND
                raise Exception("Parameter '{}' is missing when calling method '{}'".format(pname, method))
        res[pname] = ts4.check_param_names_rec(params[pname], ts4.AbiType(param))
    return res

ts4.check_method_params = check_method_params
# endregion