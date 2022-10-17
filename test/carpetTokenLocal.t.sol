// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {click_to_start_mayhem} from "../src/click_to_start_mayhem.sol";
import {carpetToken} from "../src/carpetToken.sol";
import {carpet0} from "../src/carpet0.sol";
import {carpetHelper} from "../src/carpetHelper.sol";


//these tests can all be run on a local chain, no need to plug into a fork
contract carpetTokenLocalTest is Test {
    click_to_start_mayhem public mayhem;
    carpet0 public c0;
    carpetToken public carpet;
    carpetHelper public helper;
    
    bytes createCodeCarpet = type(carpetToken).creationCode;
    bytes createCodeCarpet0 = type(carpet0).creationCode;
    bytes createCodeHelper = type(carpetHelper).creationCode;

    address Admin = address(0xad1);
    address Alice = address(0xa11ce);

    receive() external payable {}

    function setUp() public {

        vm.deal(Alice, 100 ether);
        vm.deal(address(this), 100 ether);

        bytes32[2] memory hashes;

        hashes[0] = keccak256(createCodeHelper);
        hashes[1] = keccak256(createCodeCarpet0);

        mayhem = new click_to_start_mayhem(hashes);

        //Alice must be an EOA or the tokens will go to the contract
        vm.startPrank(Alice, Alice);

        (address helperAddr, address c0Addr) = deployMayhem();

        vm.stopPrank();

        //check log to contract type
        helper = carpetHelper(payable(helperAddr));
        c0 = carpet0(payable(c0Addr));

    }

    function deployMayhem() public returns (address helperAddr, address c0Addr) {

        bytes[2] memory depCodes;
        depCodes[0] = createCodeHelper;
        depCodes[1] = createCodeCarpet0;

        (helperAddr, c0Addr) = mayhem.click_to_start_the_mayhem(depCodes);

    }

    function testMayhem() public {

        //check invariants
        //carpet0
        assertEq(c0.name(), "Carpet Token v0");
        assertEq(c0.symbol(), "CARPET0");
        assertEq(c0.decimals(), 18);
        assertEq(c0.totalSupply(), 299_999_999_999_999_999_999_997);
        assertEq(c0.balanceOf(Alice), 299_999_999_999_999_999_999_997);
        assertEq(address(c0.rugs()), 0xf70d49ec015D67738482a09c849e02e89b6FE661);
        //helper
        assertEq(address(helper.router()),0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        assertEq(helper.image(), createCodeCarpet);
    }

    // we shouldn't be allowed to carpet for 1 week
    function testFailCarpetEarly() public {
        c0.whole_new_world();
    }

    function testBuy() public {
        c0.claimForEth{value: 1 ether}();
        assertEq(c0.balanceOf(address(this)), 5_000_000*1e18);
        assertEq(c0.totalSupply(), 299_999_999_999_999_999_999_997+5_000_000*1e18);

    }

    function testApprove() public {
        assertTrue(c0.approve(address(0xBEEF), 1e18));
        assertEq(c0.allowance(address(this), address(0xBEEF)), 1e18);
    }
    
    //All transfers should fail
    function testFailTransfer() public {
        c0.claimForEth{value: 1 ether}();

        assertTrue(c0.transfer(address(0xBEEF), 1e18));
        assertEq(c0.totalSupply(), 1e18);

        assertEq(c0.balanceOf(address(this)), 0);
        assertEq(c0.balanceOf(address(0xBEEF)), 1e18);
    }

    function testFailTransferFrom() public {
        address from = Alice;

        vm.startPrank(from);
        c0.approve(address(this), 1e18);

        assertTrue(c0.transferFrom(from, address(0xBEEF), 1e18));

        assertEq(c0.balanceOf(from), 299_999_999_999_999_999_999_997);
        assertEq(c0.balanceOf(address(0xBEEF)), 0);
        vm.stopPrank();
    }

    
    function testFailInfiniteApproveTransferFrom() public {
        address from = Alice;

        vm.startPrank(from);
        c0.approve(address(this), type(uint256).max);

        assertTrue(c0.transferFrom(from, address(0xBEEF), 1e18));

        assertEq(c0.balanceOf(from), 299_999_999_999_999_999_999_997);
        assertEq(c0.balanceOf(address(0xBEEF)), 0);
        vm.stopPrank();
    }

    function testFailTransferInsufficientBalance() public {
        c0.claimForEth{value: 1 ether}();
        c0.transfer(address(0xBEEF), 1e18);
    }

    function testApprove(address to, uint256 amount) public {
        assertTrue(c0.approve(to, amount));

        assertEq(c0.allowance(address(this), to), amount);
    }


}
