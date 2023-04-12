from typing import Any

from eth.codecs import abi
from vyper.address_space import MEMORY
from vyper.ast import parse_to_ast
from vyper.builtins._signatures import BuiltinFunction
from vyper.builtins.functions import (
    DISPATCH_TABLE,
    STMT_DISPATCH_TABLE,
    abi_encode,
    ir_tuple_from_args,
    process_inputs,
)
from vyper.codegen.core import IRnode, needs_external_call_wrap
from vyper.semantics.types import ContractFunctionT, TupleT
from vyper.utils import keccak256

from boa.environment import register_precompile


class PrecompileBuiltin(BuiltinFunction):
    def __init__(self, name, args_type, return_type, address):
        # override BuiltinFunction attributes
        self._id = name
        self._inputs = args_type
        self._return_type = return_type

        # set the precompile address
        self._address = address

    @process_inputs
    def build_IR(self, expr, args, kwargs, context):
        # allocate buffer for data to pass to precompile
        # we will pass 4-byte function selector and 32-byte argument
        ret_buf = context.new_internal_variable(self._return_type)

        args_as_tuple = ir_tuple_from_args(args)
        args_abi_t = args_as_tuple.typ.abi_type
        args_buf = context.new_internal_variable(args_as_tuple.typ)

        ret = ["seq"]

        # store abi-encoded argument at buf
        args_len = abi_encode(
            args_buf, args_as_tuple, context, args_abi_t.size_bound(), returns_len=True
        )
        ret_len = self._return_type.abi_type.size_bound()

        addr = int.from_bytes(self._address, "big")

        # call precompile
        ret.append(["staticcall", "gas", addr, args_buf, args_len, ret_buf, ret_len])
        ret += [ret_buf]

        return IRnode.from_list(ret, typ=self._return_type, location=MEMORY)


# takes a user-provided signature and produces shim code for
# serializing and deserializing
# ex. precompile("def foo() -> uint256")
def precompile(user_signature: str) -> Any:
    def decorator(func):
        vy_ast = parse_to_ast(user_signature + ":\n\tpass")
        func_t = ContractFunctionT.from_FunctionDef(vy_ast, is_interface=True)
        # TODO update once ContractFunctionT is refactored
        args_t = TupleT(tuple(func_t.arguments.values()))

        def wrapper(computation):
            # Decode input arguments from message data
            message_data = computation.msg.data_as_bytes
            input_args = abi.decode(args_t, message_data)

            # Call the original function with decoded input arguments
            res = func(*input_args)

            return_t = func_t.return_type
            if return_t is not None:
                # Encode the result to be ABI-compatible
                # wrap to make it a tuple if necessary
                if needs_external_call_wrap(return_t):
                    res = (res,)
                    return_t = TupleT((return_t,))

                computation.output = abi.encode(return_t.abi_type.selector(), res)

                return computation

        address = keccak256(user_signature)[:20]
        register_precompile(address, wrapper)

        builtin = PrecompileBuiltin(func_t.name, args_t, func_t.return_type, address)

        # sketchy check to see which dispatch table it should go in
        # ideally upstream vyper should be refactored to deal with this
        if func_t.return_type is not None:
            DISPATCH_TABLE[func_t.name] = builtin
        else:
            STMT_DISPATCH_TABLE[func_t.name] = builtin

        return wrapper

    return decorator


@precompile("def printmsg(x: uint256, y: uint256) -> uint256")
def printmsg(x: int, y: int) -> int:
    print(x)
    return x + y
