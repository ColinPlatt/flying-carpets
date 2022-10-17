// SPDX-License-Identifier: The Unlicense
pragma solidity 0.8.15;

import {CREATE2_carpet} from "./CREATE2_carpet.sol";

interface ICarpetHelper {
    function image() external view returns (bytes memory);
    function router() external view returns (address);
    function name_Sym(uint256 val) external pure returns (string memory, string memory);
    function rugAndReplace(
        address currentCarpet, 
        address newCarpet
    ) external;
}

interface ICarpetParent {
    function balanceOf(address owner) external view returns (uint256);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

/// modified from transmissions11/solmate
contract carpetToken {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event WholeNewWorld(address newLocation, uint256 timestamp, uint256 iteration);

    /*//////////////////////////////////////////////////////////////
                            CARPET STORAGE
    //////////////////////////////////////////////////////////////*/

    ICarpetParent public carpetParent; //auto
    uint256 public carpetIteration;
    ICarpetHelper public carpetHelper; //auto
    uint256 public minCarpet;
    uint256 public carpetTimestamp; //set on carpet

    address public carpetChild;

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
        uint256  _carpetIteration,
        address  _carpetHelper 
    ) payable {
        carpetParent = ICarpetParent(msg.sender); //check this comes from the parent
        carpetIteration =_carpetIteration;
        carpetHelper = ICarpetHelper(_carpetHelper);
        minCarpet = block.timestamp + 10; //set this to a stupidly low amount @todo fix before deployment

        (name, symbol) = carpetHelper.name_Sym(carpetIteration);

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
        if((to == carpetHelper.router() && from == msg.sender) || msg.sender == carpetChild) {
            _transfer(from, to, amount);
            return true;
        }
        
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) {
            allowance[from][msg.sender] = allowed - amount;
        }

        _transfer(from, to, amount);
        return true;
    }

    /*//////////////////////////////////////////////////////////////
                        MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    // leave this open for testing

    function claim() public {
        require(carpetTimestamp == 0 || msg.sender == address(carpetHelper), "This ship has sailed");

        uint256 amt = carpetParent.balanceOf(msg.sender);
        carpetParent.transferFrom(msg.sender, address(this), amt);
        totalSupply += amt;

        _transfer(address(0), msg.sender, amt);

    }

    /*//////////////////////////////////////////////////////////////
                            GRASSHOPPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function whole_new_world() public returns (address newCarpet) {
        require(block.timestamp >= minCarpet, "Too early to fly.");

        carpetTimestamp = block.timestamp;

        // need to update the constructor commands
        newCarpet = CREATE2_carpet.deploy(
            address(this), 
            abi.encodePacked(
                carpetHelper.image(), 
                abi.encode(
                    carpetIteration+1,
                    address(carpetHelper)
                )
            )
        );

        carpetChild = newCarpet;

        carpetHelper.rugAndReplace(
            address(this), 
            newCarpet
        );

        emit WholeNewWorld(newCarpet, carpetTimestamp, carpetIteration+1);
    }

}
