// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {click_to_start_mayhem} from "../src/click_to_start_mayhem.sol";
import {warpToken} from "../src/warpToken.sol";
import {warp0} from "../src/warp0.sol";
import {warpHelper} from "../src/warpHelper.sol";


//these tests can all be run on a local chain, no need to plug into a fork
contract warpTokenLocalTest is Test {
    click_to_start_mayhem public mayhem;
    warp0 public w0;
    warpToken public warp;
    warpHelper public helper;
    
    bytes createCodeWarp = type(warpToken).creationCode;
    bytes createCodeWarp0 = type(warp0).creationCode;
    bytes createCodeHelper = type(warpHelper).creationCode;

    address Admin = address(0xad1);
    address Alice = address(0xa11ce);

    receive() external payable {}

    function setUp() public {

        vm.deal(Alice, 100 ether);
        vm.deal(address(this), 100 ether);

        bytes32[2] memory hashes;

        hashes[0] = keccak256(createCodeHelper);
        hashes[1] = keccak256(createCodeWarp0);

        mayhem = new click_to_start_mayhem(hashes);

        //Alice must be an EOA or the tokens will go to the contract
        vm.startPrank(Alice, Alice);

        (address helperAddr, address w0Addr) = deployMayhem();

        vm.stopPrank();

        //check log to contract type
        helper = warpHelper(payable(helperAddr));
        w0 = warp0(payable(w0Addr));

    }

    function deployMayhem() public returns (address helperAddr, address w0Addr) {

        bytes[2] memory depCodes;
        depCodes[0] = createCodeHelper;
        depCodes[1] = createCodeWarp0;

        (helperAddr, w0Addr) = mayhem.click_to_start_the_mayhem(depCodes);

    }

    function testMayhem() public {

        //check invariants
        //warp0
        assertEq(w0.name(), "Warp Token v0");
        assertEq(w0.symbol(), "WARP0");
        assertEq(w0.decimals(), 18);
        assertEq(w0.totalSupply(), 299_999_999_999_999_999_999_997);
        assertEq(w0.balanceOf(Alice), 299_999_999_999_999_999_999_997);
        assertEq(address(w0.rugs()), 0xf70d49ec015D67738482a09c849e02e89b6FE661);
        //helper
        assertEq(address(helper.router()),0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        assertEq(helper.image(), createCodeWarp);
    }

    // we shouldn't be allowed to warp for 1 week
    function testFailWarpEarly() public {
        w0.warp();
    }

    function testBuy() public {
        w0.claimForEth{value: 1 ether}();
        assertEq(w0.balanceOf(address(this)), 5_000_000*1e18);
        assertEq(w0.totalSupply(), 299_999_999_999_999_999_999_997+5_000_000*1e18);

    }

    function testApprove() public {
        assertTrue(w0.approve(address(0xBEEF), 1e18));
        assertEq(w0.allowance(address(this), address(0xBEEF)), 1e18);
    }
    
    //All transfers should fail
    function testFailTransfer() public {
        w0.claimForEth{value: 1 ether}();

        assertTrue(w0.transfer(address(0xBEEF), 1e18));
        assertEq(w0.totalSupply(), 1e18);

        assertEq(w0.balanceOf(address(this)), 0);
        assertEq(w0.balanceOf(address(0xBEEF)), 1e18);
    }

    function testFailTransferFrom() public {
        address from = Alice;

        vm.startPrank(from);
        w0.approve(address(this), 1e18);

        assertTrue(w0.transferFrom(from, address(0xBEEF), 1e18));

        assertEq(w0.balanceOf(from), 299_999_999_999_999_999_999_997);
        assertEq(w0.balanceOf(address(0xBEEF)), 0);
        vm.stopPrank();
    }

    
    function testFailInfiniteApproveTransferFrom() public {
        address from = Alice;

        vm.startPrank(from);
        w0.approve(address(this), type(uint256).max);

        assertTrue(w0.transferFrom(from, address(0xBEEF), 1e18));

        assertEq(w0.balanceOf(from), 299_999_999_999_999_999_999_997);
        assertEq(w0.balanceOf(address(0xBEEF)), 0);
        vm.stopPrank();
    }

    function testFailTransferInsufficientBalance() public {
        w0.claimForEth{value: 1 ether}();
        w0.transfer(address(0xBEEF), 1e18);
    }

    function testApprove(address to, uint256 amount) public {
        assertTrue(w0.approve(to, amount));

        assertEq(w0.allowance(address(this), to), amount);
    }


}
