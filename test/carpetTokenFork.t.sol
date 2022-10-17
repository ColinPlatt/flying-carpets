// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {click_to_start_mayhem} from "../src/click_to_start_mayhem.sol";
import {carpetToken} from "../src/carpetToken.sol";
import {carpet0} from "../src/carpet0.sol";
import {carpetHelper} from "../src/carpetHelper.sol";

import {IUniswapV2Router01} from 'v2-periphery/interfaces/IUniswapV2Router01.sol';


// tests must be run on a fork of mainnet
// forge test --match-path test/carpetTokenFork.t.sol --fork-url $RPC_URL
contract carpetTokenForkTest is Test {
    click_to_start_mayhem public mayhem;
    carpet0 public c0;
    carpetToken public carpet;
    carpetHelper public helper;
    
    bytes createCodeCarpet = type(carpetToken).creationCode;
    bytes createCodeCarpet0 = type(carpet0).creationCode;
    bytes createCodeHelper = type(carpetHelper).creationCode;

    address Admin = address(0xad1);
    address Alice = address(0xa11ce);

    address Apely = address(0x5CAfbD5aE3EBEEfEAE0a1ef6ef21177df4e961a4); //use to check claim for Rugs (holds 27 on 05102022)

    string MAINNET_RPC_URL = vm.envString("RPC_URL");
    string MAINNET_RPC_URL_ALT = vm.envString("RPC_URL_ALT");
    uint256 mainnetFork;

    address helperAddr;
    address c0Addr;

    receive() external payable {}

    function setUp() public {
        
        mainnetFork = vm.createSelectFork(MAINNET_RPC_URL_ALT, 15681600);
        vm.selectFork(mainnetFork);

        vm.deal(Alice, 100 ether);
        vm.deal(address(this), 100 ether);

        bytes32[2] memory hashes;

        hashes[0] = keccak256(createCodeHelper);
        hashes[1] = keccak256(createCodeCarpet0);

        mayhem = new click_to_start_mayhem(hashes);

        //Alice must be an EOA or the tokens will go to the contract
        vm.startPrank(Alice, Alice);

        (helperAddr, c0Addr) = deployMayhem();

        vm.stopPrank();

        //check log to contract type
        helper = carpetHelper(payable(helperAddr));
        c0 = carpet0(payable(c0Addr));

        vm.makePersistent(helperAddr);
        vm.makePersistent(c0Addr);

    }

    function deployMayhem() public returns (address _helperAddr, address _c0Addr) {

        bytes[2] memory depCodes;
        depCodes[0] = createCodeHelper;
        depCodes[1] = createCodeCarpet0;

        (_helperAddr, _c0Addr) = mayhem.click_to_start_the_mayhem(depCodes);

    }

    function claimAllForETH() public {
        c0.claimForEth{value: 10 ether}();
        assertEq(c0.balanceOf(address(this)), 50_000_000*1e18);
        assertEq(c0.totalSupply(), 299_999_999_999_999_999_999_997+50_000_000*1e18);

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
            c0.claimForRugs(nftIds[i]);
        }
        
        vm.stopPrank();
    }

    function testClaimForApelysRugs() public {
        
        makeApelyClaims();

        assertEq(c0.balanceOf(Apely), 6*c0.CARPETS_PER_RUGS());
        assertEq(c0.totalSupply(), 299_999_999_999_999_999_999_997+6*c0.CARPETS_PER_RUGS());
    }

    address c1;
    address c1LPToken;
    function testFirstCarpet() public {

        assertEq(vm.activeFork(), mainnetFork);

        claimAllForETH();

        makeApelyClaims();

        // move ahead 100 blocks
        vm.rollFork(uint256(15681700));

        vm.startPrank(Alice, Alice);

        uint256 AliceW0Bal = c0.balanceOf(Alice);
        c1 = c0.whole_new_world();

        carpetToken(c1).claim();
        
        vm.stopPrank();

        assertEq(AliceW0Bal, carpetToken(c1).balanceOf(Alice));
        assertEq(0, c0.balanceOf(Alice));

        c1LPToken = UniswapV2Library.pairFor(IUniswapV2Router01(address(helper.router())).factory(), IUniswapV2Router01(address(helper.router())).WETH(), c1);
        vm.makePersistent(c1);
        vm.makePersistent(c1LPToken);
    }

    function testTransfers() public {

        testFirstCarpet();

        assertEq(vm.activeFork(), mainnetFork);

        // move ahead of the setup
        vm.rollFork(uint256(15681701));

        vm.startPrank(Alice, Alice);

            carpetToken(c1).transfer(Apely, 1e18);
            assertEq(carpetToken(c1).balanceOf(Apely),1e18);
            assertEq(carpetToken(c1).balanceOf(Alice),299999999999999999999997-1e18);

            carpetToken(c1).approve(Apely, 2e18);
                
        vm.stopPrank();

        vm.startPrank(Apely);
            carpetToken(c1).transferFrom(Alice, Apely, 2e18);
            assertEq(carpetToken(c1).balanceOf(Apely),3e18);
            assertEq(carpetToken(c1).balanceOf(Alice),299999999999999999999997-3e18);

        vm.stopPrank();

    }

    function testFailTransferFrom() public {

        testFirstCarpet();

        assertEq(vm.activeFork(), mainnetFork);

        // move ahead of the setup
        vm.rollFork(uint256(15681701));

        vm.startPrank(Alice, Alice);

            carpetToken(c1).transfer(Apely, 1e18);
            assertEq(carpetToken(c1).balanceOf(Apely),1e18);
            assertEq(carpetToken(c1).balanceOf(Alice),299999999999999999999997-1e18);

            carpetToken(c1).approve(Apely, 2e18);
                
        vm.stopPrank();

        vm.startPrank(Apely);
            carpetToken(c1).transferFrom(Alice, Apely, 3e18);

        vm.stopPrank();

    }

    function testFailTransferFromNoApprove() public {

        testFirstCarpet();

        assertEq(vm.activeFork(), mainnetFork);

        // move ahead of the setup
        vm.rollFork(uint256(15681701));

        vm.startPrank(Alice, Alice);

            carpetToken(c1).transfer(Apely, 1e18);
            assertEq(carpetToken(c1).balanceOf(Apely),1e18);
            assertEq(carpetToken(c1).balanceOf(Alice),299999999999999999999997-1e18);
                
        vm.stopPrank();

        vm.startPrank(Apely);
            carpetToken(c1).transferFrom(Alice, Apely, 3e18);

        vm.stopPrank();

    }

    address c2;
    
    address c2LPToken;
    function testSecondCarpet() public {

        assertEq(vm.activeFork(), mainnetFork);

        claimAllForETH();

        makeApelyClaims();

        // move ahead 100 blocks
        vm.rollFork(uint256(15681700));

        vm.startPrank(Alice, Alice);

        uint256 AliceW0Bal = c0.balanceOf(Alice);
        c1 = c0.whole_new_world();
        carpetToken(c1).claim();
        assertEq(0, c0.balanceOf(Alice));
            
        vm.stopPrank();

        assertEq(AliceW0Bal, carpetToken(c1).balanceOf(Alice));

        c1LPToken = UniswapV2Library.pairFor(IUniswapV2Router01(address(helper.router())).factory(), IUniswapV2Router01(address(helper.router())).WETH(), c1);
        vm.makePersistent(c1);
        vm.makePersistent(c1LPToken);
        vm.makePersistent(helperAddr);
        vm.makePersistent(c0Addr);
        vm.makePersistent(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

        // move ahead 100 blocks
        vm.rollFork(uint256(15681800));

        vm.startPrank(Alice, Alice);

        c2 = carpetToken(c1).whole_new_world();
        carpetToken(c2).claim();
        c2LPToken = UniswapV2Library.pairFor(IUniswapV2Router01(address(helper.router())).factory(), IUniswapV2Router01(address(helper.router())).WETH(), c2);
        vm.makePersistent(c2);
        vm.makePersistent(c2LPToken);

        vm.stopPrank();

        assertEq(AliceW0Bal, carpetToken(c2).balanceOf(Alice));
        assertEq(0, carpetToken(c1).balanceOf(Alice));

    }

    function testFailClaimExpired() public {

        testSecondCarpet();

        assertEq(vm.activeFork(), mainnetFork);

        // move ahead of the setup
        vm.rollFork(uint256(15681801));


        vm.startPrank(Apely);
            carpetToken(c1).claim();

        vm.stopPrank();

    }




}

library UniswapV2Library {
    
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }
    
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            )))));
    }

}
