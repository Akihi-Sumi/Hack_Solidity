//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "./Helper.sol";

contract MEC {
    Helper helper;
    constructor(address _helper) {
        helper = Helper(_helper);
    }

    // Heper public helper;
    // constructor(address _helper) {
    //     helper = new Helper();
    // }

    function isUserEligible() public view returns(bool) {
        return helper.isUserEligible(msg.sender);
    }

    function addUserToList() public  {
        helper.setUserEligible(msg.sender);
    }

    fallback() external {}
}