// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {click_to_start_mayhem} from "../src/click_to_start_mayhem.sol";
import {warpToken} from "../src/warpToken.sol";
import {warp0} from "../src/warp0.sol";
import {warpHelper} from "../src/warpHelper.sol";

// tests must be run on a fork of mainnet
// forge test --match-path test/warpTokenFork.t.sol --fork-url $RPC_URL
contract warpTokenForkTest is Test {
    click_to_start_mayhem public mayhem;
    warp0 public w0;
    warpToken public warp;
    warpHelper public helper;
    
    bytes createCodeWarp = type(warpToken).creationCode;
    bytes createCodeWarp0 = type(warp0).creationCode;
    bytes createCodeHelper = type(warpHelper).creationCode;

    address Admin = address(0xad1);
    address Alice = address(0xa11ce);

    address Apely = address(0x5CAfbD5aE3EBEEfEAE0a1ef6ef21177df4e961a4); //use to check claim for Rugs (holds 27 on 05102022)

    string MAINNET_RPC_URL = vm.envString("RPC_URL");
    string MAINNET_RPC_URL_ALT = vm.envString("RPC_URL_ALT");
    uint256 mainnetFork;

    address helperAddr;
    address w0Addr;

    receive() external payable {}

    function setUp() public {
        
        mainnetFork = vm.createSelectFork(MAINNET_RPC_URL, 15681700);
        vm.selectFork(mainnetFork);

        vm.deal(Alice, 100 ether);
        vm.deal(address(this), 100 ether);

        bytes32[2] memory hashes;

        hashes[0] = keccak256(createCodeHelper);
        hashes[1] = keccak256(createCodeWarp0);

        mayhem = new click_to_start_mayhem(hashes);

        //Alice must be an EOA or the tokens will go to the contract
        vm.startPrank(Alice, Alice);

        (helperAddr, w0Addr) = deployMayhem();

        vm.stopPrank();

        //check log to contract type
        helper = warpHelper(payable(helperAddr));
        w0 = warp0(payable(w0Addr));

        vm.makePersistent(helperAddr);
        vm.makePersistent(w0Addr);

    }

    function deployMayhem() public returns (address helperAddr, address w0Addr) {

        bytes[2] memory depCodes;
        depCodes[0] = createCodeHelper;
        depCodes[1] = createCodeWarp0;

        (helperAddr, w0Addr) = mayhem.click_to_start_the_mayhem(depCodes);

    }

    function claimAllForETH() public {
        w0.claimForEth{value: 10 ether}();
        assertEq(w0.balanceOf(address(this)), 50_000_000*1e18);
        assertEq(w0.totalSupply(), 299_999_999_999_999_999_999_997+50_000_000*1e18);

    }

    function makeApelyClaims() public {
        
        uint256[6] memory nftIds;
        nftIds[0] = 2;
        nftIds[1] = 3;
        nftIds[2] = 4;
        nftIds[3] = 119;
        nftIds[4] = 120;
        nftIds[5] = 121;

        vm.startPrank(Apely);

        for(uint256 i = 0; i<6; i++) {
            w0.claimForRugs(nftIds[i]);
        }
        
        vm.stopPrank();
    }

    function _testClaimForApelysRugs() public {
        
        makeApelyClaims();

        assertEq(w0.balanceOf(Apely), 6*w0.WARPS_PER_RUGS());
        assertEq(w0.totalSupply(), 299_999_999_999_999_999_999_997+6*w0.WARPS_PER_RUGS());
    }

    function testFirstWarp() public {

        assertEq(vm.activeFork(), mainnetFork);

        w0.claimForEth{value: 10 ether}();
        uint256[6] memory nftIds;
        nftIds[0] = 2;
        nftIds[1] = 3;
        nftIds[2] = 4;
        nftIds[3] = 119;
        nftIds[4] = 120;
        nftIds[5] = 121;

        vm.startPrank(Apely);

        for(uint256 i = 0; i<6; i++) {
            w0.claimForRugs(nftIds[i]);
        }
        
        vm.stopPrank();

        // move ahead 1 week and 1 second
        vm.createSelectFork(MAINNET_RPC_URL, 15681800);

        emit log_uint(Alice.balance);

        vm.startPrank(Alice, Alice);

        address w1 = w0.warp();

        vm.stopPrank();

        emit log_address(w1);
        emit log_uint(Alice.balance);
        emit log_uint(address(helper).balance);

    }


}
