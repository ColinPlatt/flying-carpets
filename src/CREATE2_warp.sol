// SPDX-License-Identifier: MIT
// Modified from OpenZeppelin Contracts (last updated v4.7.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library CREATE2_warp {

    function deploy(
        address deployer,
        bytes memory bytecode
    ) internal returns (address addr) {
        // we check that bytecode matches when we call, so no need to check length here
        /// @solidity memory-safe-assembly
        //bytes32 salt = bytes32(uint256(uint160(deployer)));
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), deployer)
        }
        require(addr != address(0), "Create2: Failed on deploy");
    }


}

