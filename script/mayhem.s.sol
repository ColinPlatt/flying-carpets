// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/click_to_start_mayhem.sol";
import "../src/carpetHelper.sol";
import "../src/carpet0.sol";


contract MayhemScript is Script {

    carpet0 public what0;
    carpetHelper public what1;
    click_to_start_mayhem public mayhem;

    bytes32[2] _hashChecks;

    function setUp() public {
        _hashChecks[0] = keccak256(type(carpet0).creationCode);
        _hashChecks[1] = keccak256(type(carpetHelper).creationCode);

    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        mayhem = new click_to_start_mayhem(_hashChecks);

        vm.stopBroadcast();
    }
}
