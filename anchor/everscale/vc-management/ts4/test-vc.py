from dataclasses import dataclass
import os
from random import random
from ts4common import ts4, KeyPair, Address, eq, ever, zero_addr

idx_controller = KeyPair(*ts4.make_keypair())
issuer1 = KeyPair(*ts4.make_keypair())

idx_fabric: ts4.BaseContract = None

@dataclass
class ClaimGroup:
    # HMAC-secured hashes, higher 64 bits
    hmacHigh_groupDid: int
    hmacHigh_claimGroup: int
    ## 2x256 = 512 bit long signature of the full claimGroup hash
    signHighPart: int
    signLowPart: int

    def to_dict(self) -> dict:
        return vars(self)

    @staticmethod
    def from_dict(d: dict) -> 'ClaimGroup':
        for k,v in d.items():
            d[k] = int(v)
        return ClaimGroup(**d)

    def eq(self, other: 'ClaimGroup') -> bool:
        return all(map(lambda p: p[0][1] == p[1][1],zip(vars(self), vars(other))))

def test_deploy_fabric():
    global idx_fabric
    params = dict(vcBaseImage = ts4.load_code_cell('IdxVc_type1'))
    idx_fabric = ts4.BaseContract('IdxVcFabric', params, balance=20*ever, keypair=idx_controller, nickname='Fabric')
    Address.ensure_address(idx_fabric.address)
    assert idx_fabric.g.codeVer() > 0


def test_issue_vc():
    claims: list[ClaimGroup] = [gen_claim() for _ in range(3)]
    vc_addr = idx_fabric.call_method_signed('issueVc', dict(claims=[c.to_dict() for c in claims], issuerPubKey=issuer1.public))
    ts4.dispatch_one_message()
    vc = ts4.BaseContract('IdxVc_type1', None, address=vc_addr)
    for i, cg in enumerate(map(ClaimGroup.from_dict, vc.g.claimGroups())):
        assert claims[i].eq(cg)
        # eq(cg, doc.g.idxAuthority())
    eq(int(issuer1.public, 16), vc.g.issuerPubKey())
    assert vc.g.codeVer() > 0


def gen_claim() -> ClaimGroup:
    return ClaimGroup(\
        hmacHigh_claimGroup=urandom(64),
        hmacHigh_groupDid=urandom(64),
        signHighPart=urandom(256),
        signLowPart=urandom(256))

def urandom(bits: int):
    return int.from_bytes(os.urandom(bits // 8), 'big')

test_deploy_fabric()
test_issue_vc()

# Ensure we have no undispatched messages
ts4.ensure_queue_empty()