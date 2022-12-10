// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Game {
    constructor() payable {}

    /**
         Randomly picks a number out of `0 to 2²⁵⁶–1`.
    */
    function pickACard() private view returns(uint) {
        // `abi.encodePacked` は `blockhash` と `block.timestamp` という二つのパラメータを受け取ってバイト配列を返し、
        // それがさらに keccak256 に渡されて `bytes32` を返し、それがさらに `uint` に変換されます。
        // keccak256は、バイト配列を受け取ってbytes32に変換するハッシュ関数である。
        uint pickedCard = uint(keccak256(abi.encodePacked(blockhash(block.number), block.timestamp)));
        return pickedCard;
    }

    /**
        まず、`pickACard`を呼び出して乱数を選択することでゲームを開始します。
        そして、選択された乱数が、プレイヤーから渡された `_guess` と等しいかどうかを検証する。
        正解の場合、プレイヤーに 0.1 ether を送ります。
    */
    function guess(uint _guess) public {
        uint _pickedCard = pickACard();
        if(_guess == _pickedCard){
            (bool sent,) = msg.sender.call{value: 0.1 ether}("");
            require(sent, "Failed to send ether");
        }
    }

    /**
        コントラクト内のetherの残高を返します。
    */
    function getBalance() view public returns(uint) {
          return address(this).balance;
    }

}