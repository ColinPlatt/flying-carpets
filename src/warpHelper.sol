// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// this contract holds useful information that we can offload, and handles Uniswap interactions.

import {LibString} from 'solmate/utils/LibString.sol';
import {IUniswapV2Router01} from 'v2-periphery/interfaces/IUniswapV2Router01.sol';
import {CREATE2_warp} from "./CREATE2_warp.sol";


interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IWarp {
    function claim(address to, uint256 amount) external;
}

contract warpHelper {

    bytes               public image;
    IUniswapV2Router01  public router;

    address             public currentLPToken;
    IERC20              public constant weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    constructor(
        bytes memory    _image, 
        address         _router
    ) {
        image         = _image;
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

    function rugAndReplace(address currentWarp, address newWarp, uint256 _gasPostDeployment, address _warper) public {
        //check that this comes from the current version of warp
        require(msg.sender == currentWarp, "PRETTY FUNNY");

        uint256 gasPreRug = gasleft();

        //fetch the current lp token

        // approve the LP to be sent to the router upon removal
        IERC20(currentLPToken).approve(
            address(router), 
            IERC20(currentLPToken).balanceOf(address(this))
        );

        //remove all liquidity
        (uint amountToken,) = router.removeLiquidityETH(
            currentWarp,
            IERC20(currentLPToken).balanceOf(currentLPToken),
            IERC20(currentLPToken).balanceOf(currentLPToken),
            weth.balanceOf(currentLPToken),
            address(this),
            block.timestamp
        );

        //mint a number of newWarp equal to what was removed from the LP
        IWarp(newWarp).claim(address(this), amountToken);

        // approve newWarp and add new liquidity

        // refund warper

    }

}