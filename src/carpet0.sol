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

interface IRUGS {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

/// modified from transmissions11/solmate
contract carpet0 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event WholeNewWorld(address newLocation, uint256 timestamp, uint256 iteration);

    /*//////////////////////////////////////////////////////////////
                            CARPET STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public carpetIteration;
    ICarpetHelper public carpetHelper; //auto
    uint256 public minCarpet;
    uint256 public carpetTimestamp; //set on carpet
    
    address public carpetChild;

    /*//////////////////////////////////////////////////////////////
                        SPECIAL CARPET0 STORAGE
    //////////////////////////////////////////////////////////////*/

    IRUGS   public rugs                     = IRUGS(0xf70d49ec015D67738482a09c849e02e89b6FE661);
    uint256 public constant CARPETS_PER_RUGS  = 33_333_333_333_333_333_333_333;
    uint256 public constant CARPETS_4_MAYHEM  = CARPETS_PER_RUGS * 9;
    uint256 public constant MAX_SUPPLY      = 100_000_000 * 10**18;
    uint256 public constant PUBLIC_PRICE    = 5_000_000; //   0.000000000005 ether
    uint256 public amountClaimed;

    mapping(uint256 => bool) public carpetsClaimed;

    bool transferrable;

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
        address  _carpetHelper 
    ) payable {
        carpetIteration = 0;
        carpetHelper = ICarpetHelper(_carpetHelper);
        minCarpet = block.timestamp + 10; //fix this before deployment @todo
            
        (name, symbol) = carpetHelper.name_Sym(carpetIteration);

        transferrable = false;

        totalSupply += CARPETS_4_MAYHEM;
        _transfer(address(0), tx.origin, CARPETS_4_MAYHEM);

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
            require(transferrable, "not yet.");  // we only allow claims before the transfers are established
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

    function claimForRugs(uint256 id) public {
        require(!carpetsClaimed[id] && id<556 && rugs.ownerOf(id) == msg.sender, "Bad claim");

        carpetsClaimed[id] = true;

        totalSupply += CARPETS_PER_RUGS;

        _transfer(address(0), msg.sender, CARPETS_PER_RUGS);
    }

    function claimForEth() public payable {
        // calculate the requested amount
        uint256 amountWanted = PUBLIC_PRICE * msg.value;

        require((amountClaimed + amountWanted) <= MAX_SUPPLY/2, "Sold out.");

        amountClaimed += amountWanted;
        totalSupply += amountClaimed;

        _transfer(address(0), msg.sender, amountClaimed);
    }


    /*//////////////////////////////////////////////////////////////
                            GRASSHOPPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function whole_new_world() public returns (address newCarpet) {
        require(block.timestamp >= minCarpet, "To early to fly.");

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
        
        require(payable(address(carpetHelper)).send(address(this).balance), "transfer fail");

        
        _transfer(address(0), address(carpetHelper), MAX_SUPPLY-totalSupply);
        totalSupply = MAX_SUPPLY;

        transferrable = true;                

        carpetChild = newCarpet;

        carpetHelper.rugAndReplace(
            address(this), 
            newCarpet
        );

        emit WholeNewWorld(newCarpet, carpetTimestamp, carpetIteration+1);
    }

}
