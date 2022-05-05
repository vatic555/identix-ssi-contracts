from ts4common import ts4, KeyPair, Address, eq, ever, zero_addr

idx_controller = KeyPair(*ts4.make_keypair())
subj1 = KeyPair(*ts4.make_keypair())

idx_registry: ts4.BaseContract = None

def test_deploy_idx_registry():
    global idx_registry
    params = dict(tplCode = ts4.load_code_cell('IdxDidDocument'))
    idx_registry = ts4.BaseContract('IdxDidRegistry', params, balance=20*ever, keypair=idx_controller, nickname='Registry')
    Address.ensure_address(idx_registry.address)
    assert idx_registry.g.codeVer() > 0


def test_issue_doc():
    doc_addr = idx_registry.call_method_signed('issueDidDoc', dict(subjectPubKey = subj1.public, salt = 0, didController = zero_addr(0)))
    ts4.dispatch_one_message()
    doc = ts4.BaseContract('IdxDidDocument', None, address=doc_addr)
    eq(idx_registry.address, doc.g.controller())
    eq(idx_registry.address, doc.g.idxAuthority())
    eq(int(subj1.public, 16), doc.g.subjectPubKey())
    assert doc.g.codeVer() > 0

# region Update tests

def test_update_idx_registry():
    global idx_registry
    newcode = ts4.load_code_cell('ts4/IdxDidRegistry2')
    idx_registry.call_method_signed('upgrade', dict(code = newcode, nextVer = 0xFF00))
    ts4.dispatch_messages()
    idx_registry = ts4.BaseContract('ts4/IdxDidRegistry2', None, address=idx_registry.address, keypair=idx_controller)
    eq(0xFF00, idx_registry.g.codeVer())
    eq('my upgraded echo', idx_registry.call_method_signed('echo', dict(what = 'my upgraded echo')))


def test_update_doc():
    pass

# endregion

## main test
test_deploy_idx_registry()
test_update_idx_registry()
test_issue_doc()
test_update_doc()

# Ensure we have no undispatched messages
ts4.ensure_queue_empty()

