// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import {Create2} from "@Openzeppelin/utils/Create2.sol";

/* 

This contract allows 2 contract2 with bytecode matching the hashcheck to be sent to deploy2
*/

contract click_to_start_mayhem {

    bytes32 public immutable hashCheck0;
    bytes32 public immutable hashCheck1;

    constructor(
        bytes32[2] memory _hashChecks
    ) {
        hashCheck0 = _hashChecks[0];
        hashCheck1 = _hashChecks[1];
    }

    
    //takes a set of bytes and runs it through a Create2 if this contract is lockedAndLoaded and the hash of the input bytes matches the hash loaded in the contstructor
    function click_to_start_the_mayhem(bytes[2] calldata what) public returns (address where, address accomplice) {
        require(keccak256(what[0]) == hashCheck0 && keccak256(what[1]) == hashCheck1, "Not that.");

        where = Create2.deploy(
            0,
            keccak256(
                abi.encodePacked(
                    hashCheck0,
                    address(this)
                )
            ),
            what[0]
        );

        accomplice = Create2.deploy(
            0,
            keccak256(
                abi.encodePacked(
                    hashCheck1,
                    address(this)
                )
            ),
            what[1]
        );        
    }
}