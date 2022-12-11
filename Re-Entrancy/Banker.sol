// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts@4.8.0/utils/Address.sol";
// import "@openzeppelin/contracts@4.8.0/security/ReentrancyGurad.sol";
import "hardhat/console.sol";

contract Banker {
// contract Banker is ReentrancyGurad {
    using Address for address payable;

    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external {
    // function withdraw() external noReetrant {
        require(
            balances[msg.sender] > 0,
            "Withdrawl amount exceeds available balance."
        );

        console.log("");
        console.log("Banker balance: ", address(this).balance);
        console.log("Attacker balance: ", balances[msg.sender]);
        console.log("");

        payable(msg.sender).sendValue(balances[msg.sender]);
        balances[msg.sender] = 0;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}