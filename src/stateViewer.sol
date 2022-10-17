// SPDX-License-Identifier: The Unlicense
pragma solidity 0.8.15;

interface ICarpet{
    function balanceOf(address owner) external view returns (uint256);
    function carpetChild() external view returns (address);
    function carpetParent() external view returns (address);
}

interface IMayhem{
    function deployedWhere() external view returns (address);
    function deployedAccomplice() external view returns (address);
}

contract stateViewer {

    IMayhem mayhem;
    
    enum STATE {
        undeployed,
        carpet0,
        carpetN
    }

    constructor(address _mayhem) {
        mayhem = IMayhem(_mayhem);
    }

    function getState() public view returns (STATE currentState) {
        if (mayhem.deployedWhere() == address(0)) {
            return STATE.undeployed;
        } else {
            ICarpet carpet0 = ICarpet(mayhem.deployedWhere());
            if(carpet0.carpetChild() == address(0)){
                return STATE.carpet0;
            } else {
                return STATE.carpetN;
            }
        }
    }

    function getCarpets() public view returns (address currentCarpet, address lastCarpet) {
        
        STATE currentState = getState();

        require(currentState != STATE.undeployed, "no carpets");

        if(currentState == STATE.carpet0) {
            currentCarpet = address(ICarpet(mayhem.deployedWhere()));
            lastCarpet = address(0);
        } else {
            // set to carpet0
            ICarpet tmpCarpet = ICarpet(mayhem.deployedWhere());

            unchecked {
                while(tmpCarpet.carpetChild() != address(0)) {
                    tmpCarpet = ICarpet(tmpCarpet.carpetChild());
                }
            }
        
            currentCarpet = address(tmpCarpet);
            lastCarpet = address(tmpCarpet.carpetParent());

        }

    }

}