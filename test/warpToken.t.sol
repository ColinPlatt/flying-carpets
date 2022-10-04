// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {warpToken} from "../src/warpToken.sol";
import {warpHelper} from "../src/warpHelper.sol";

contract warpTokenTest is Test {
    warpToken public warp;
    warpHelper public helper;
    
    bytes createCode;
    
    function setUp() public {

       vm.deal(msg.sender, 100 ether);
       
       createCode = type(warpToken).creationCode;

       helper = new warpHelper(address(0));
       warp = new warpToken{value: 1 ether}(0,address(helper));

    }

    function testSize() public {

        emit log_uint(createCode.length);
        assertEq(helper.image(), createCode);
    }

    function testMint() public {
        warp.claim();
    }

    function testWarp() public {
        assertEq(address(warp).balance, 1 ether);

        warp.claim();

        warpToken warp1 = warpToken(warp.warp());

        assertEq(address(warp).balance, 0 ether);
        assertEq(address(warp1).balance, 1 ether);
    }

}
