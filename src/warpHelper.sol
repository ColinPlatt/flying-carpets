// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// this contract holds useful information that we can offload, and handles Uniswap interactions.

import {LibString} from 'solmate/utils/LibString.sol';
import {IUniswapV2Router01} from 'v2-periphery/interfaces/IUniswapV2Router01.sol';

import {warpToken} from './warpToken.sol';

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

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract warpHelper {

    bytes               public image;
    IUniswapV2Router01  public router;

    constructor(
        address         _router
    ) {
        image         = type(warpToken).creationCode;
        router        = IUniswapV2Router01(_router);
    }

    receive() external payable {}

    function name_Sym(uint256 val) public pure returns (string memory, string memory) {
        return (
            string.concat(
                "Warp Token v", 
                LibString.toString(val)
            ), 
            string.concat(
                "WARP", 
                LibString.toString(val)
            )
        );
    }

    function rugAndReplace(address currentWarp, address newWarp, uint256 _gasStart) public {
        //check that this comes from the current version of warp
        require(msg.sender == currentWarp, "PRETTY FUNNY");

        //fetch the current lp token
        address currentLPToken = UniswapV2Library.pairFor(router.factory(), router.WETH(), currentWarp);

        uint amountEthCurrent;

        //check if this follows warp1...N logic
        if(IERC20(currentLPToken).balanceOf(address(this)) > 0){
            // approve the LP to be sent to the router upon removal
            IERC20(currentLPToken).approve(
                address(router), 
                IERC20(currentLPToken).balanceOf(address(this))
            );

            //remove all liquidity
            (, amountEthCurrent) = router.removeLiquidityETH(
                currentWarp,
                IERC20(currentLPToken).balanceOf(currentLPToken),
                IERC20(currentLPToken).balanceOf(currentLPToken),
                IERC20(router.WETH()).balanceOf(currentLPToken),
                address(this),
                block.timestamp
            );
        } else {
            amountEthCurrent = address(this).balance;
        }

        //mint a number of newWarp equal to what was removed from the LP
        warpToken(newWarp).claim();
        uint newWarpBalance = IERC20(newWarp).balanceOf(address(this));

        //figure out how much ETH to leave
        uint gasToSave = (_gasStart - gasleft() + 450_000) * block.basefee;
        if(gasToSave >= amountEthCurrent) gasToSave = 0;

        // add new liquidity, approve should be automatic now
        router.addLiquidityETH(
            newWarp,
            newWarpBalance,
            newWarpBalance,
            (amountEthCurrent - gasToSave),
            address(this),
            block.timestamp
        );

        // refund warper
        payable(tx.origin).transfer(address(this).balance);

    }

}