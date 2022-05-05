from functools import cache
import os
import json
from glob import glob
from typing import Any, Callable
from unittest import result
import jsonschema.validators as jsv

BASE_PATH = os.path.abspath(os.getcwd()) + '/schemas'

class JSONWithCommentsDecoder(json.JSONDecoder):
    def __init__(self, **kw):
        super().__init__(**kw)

    def decode(self, s: str) -> Any:
        s = '\n'.join(l for l in s.split('\n') if not l.lstrip(' ').startswith('//'))
        return super().decode(s)


def jload(fn: str):
    try:
        with open(fn, 'r') as f:
            return json.load(f, cls=JSONWithCommentsDecoder)
    except json.JSONDecodeError as ex:
        print(f'Error in {fn.removeprefix(BASE_PATH)}\n{ex.args[0]}')
        quit(1)

predicate_schema = jload('schemas/meta/predicate')
vccs_schema = jload('schemas/meta/vccs')
vc_schema = jload('schemas/vc/vc_jwt_v1')

cache = {}

def local_ref_resolve_remote(inherited, uri: str):
    result = cache.get(uri)
    if result is not None:
        return result
    if uri.startswith('https://schemas.identix.space'):
        result = jload(uri.replace('https://schemas.identix.space', BASE_PATH))
        cache[uri] = result
        return result
    return inherited(uri)

idx_pred_validator = jsv.Draft202012Validator(predicate_schema)
inherited = idx_pred_validator.resolver.resolve_remote
idx_pred_validator.resolver.resolve_remote = lambda url: local_ref_resolve_remote(inherited, url)

idx_vccs_validator = jsv.Draft202012Validator(vccs_schema)
inherited = idx_vccs_validator.resolver.resolve_remote
idx_vccs_validator.resolver.resolve_remote = lambda url: local_ref_resolve_remote(inherited, url)

idx_vc_validator = jsv.Draft202012Validator(vc_schema)
inherited = idx_vc_validator.resolver.resolve_remote
idx_vc_validator.resolver.resolve_remote = lambda url: local_ref_resolve_remote(inherited, url)

predicates = list(map(jload, glob(BASE_PATH + '/core/*'))) \
           + list(map(jload, glob(BASE_PATH + '/officials/*')))
vccs_examples = list(map(jload, glob(BASE_PATH + '/examples/vccs/*')))
vc_examples = list(map(jload, glob(BASE_PATH + '/examples/vc/*')))

for p in predicates:
    idx_pred_validator.validate(p)
    print(p['id'])

for vcs in vccs_examples:
    idx_vccs_validator.validate(vcs)
    print(vcs['id'])

for vcs in vc_examples:
    idx_vc_validator.validate(vcs)
    print(vcs['payload']['jti'])
