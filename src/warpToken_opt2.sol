// SPDX-License-Identifier: The Unlicense
pragma solidity 0.8.15;

import {CREATE2_warp} from "./CREATE2_warp.sol";

interface IWarpHelper {
    function image() external view returns (bytes memory);
    function router() external view returns (address);
    function name_Sym(uint256 val) external pure returns (string memory, string memory);
    function rugAndReplace(
        address currentWarp, 
        address newWarp, 
        uint256 _gasPostDeployment, 
        address _warper
    ) external;
}

interface IWarpParent {
    function balanceOf(address owner) external view returns (uint256);
}

/// modified from transmissions11/solmate
contract warpToken {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Warp(address newLocation, uint256 timestamp, uint256 iteration);

    /*//////////////////////////////////////////////////////////////
                            WARP STORAGE
    //////////////////////////////////////////////////////////////*/

    IWarpParent warpParent; //auto
    uint256 warpIteration;
    IWarpHelper warpHelper; //auto
    uint256 minWarp;
    uint256 warpTimestamp; //set on warp

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public constant decimals = 18;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        uint256  _warpIteration,
        address  _warpHelper 
    ) payable {
        warpParent = IWarpParent(msg.sender); //check this comes from the parent
        warpIteration =_warpIteration;
        warpHelper = IWarpHelper(_warpHelper);
        minWarp = block.timestamp + 2_592_000;
            
        (name, symbol) = warpHelper.name_Sym(_warpIteration);

    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if(_from != address(0)) {
            balanceOf[_from] -= _amount;
        }

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[_to] += _amount;
        }

        emit Transfer(_from, _to, _amount);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max || to != warpHelper.router()) {
            allowance[from][msg.sender] = allowed - amount;
        }

        _transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                        MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    // leave this open for testing
    // @todo fix possibility that someone receives after the warp
    function claim() public {
        require(warpTimestamp == 0 || msg.sender == address(warpHelper), "This ship has sailed");

        totalSupply += warpParent.balanceOf(msg.sender);

        _transfer(address(0), msg.sender, warpParent.balanceOf(msg.sender));

    }

    /*//////////////////////////////////////////////////////////////
                            GRASSHOPPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function warp() public returns (address newWarp) {
        require(block.timestamp >= minWarp, "To early to warp.");

        uint256 gasEntry = gasleft();

        warpTimestamp = block.timestamp;

        // need to update the constructor commands
        newWarp = CREATE2_warp.deploy(
            address(this), 
            abi.encodePacked(
                warpHelper.image(), 
                abi.encode(
                    warpIteration+1,
                    86400, 
                    address(warpHelper)
                )
            )
        );

        warpHelper.rugAndReplace(
            address(this), 
            newWarp, 
            gasEntry, 
            msg.sender
        );

        emit Warp(newWarp, warpTimestamp, warpIteration+1);
    }

}