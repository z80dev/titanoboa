from boa.contracts.abi.abi_contract import ABIContractFactory
from boa.environment import Env
import solcx

class SolDeployer:
    def __init__(self, abi, bytecode, filename=None, env=None):
        self.env = env or Env.get_singleton()
        self.abi = abi
        self.bytecode = bytecode
        self.filename = filename
        self.factory = ABIContractFactory.from_abi_dict(abi)

    def deploy(self):
        address, _ = self.env.deploy_code(bytecode=self.bytecode)
        return self.factory.at(address)

    def __call__(self):
        return self.deploy()

    def at(self, address):
        return self.factory.at(address)
