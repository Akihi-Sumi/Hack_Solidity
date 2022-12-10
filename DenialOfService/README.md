# Denial of Service

![image](https://user-images.githubusercontent.com/16539849/174761638-cf7c28d6-f654-4f5b-8fab-569ddc968941.png)

DOS(Denial of Service)攻撃とは、ネットワーク、ウェブサイト、サービスなどを不能にしたり、停止させたり、妨害したりすることを目的とした攻撃の一種です。
基本的には、攻撃者が何らかの方法でネットワーク、ウェブサイト、またはサービスへの一般ユーザーのアクセスを阻止し、サービスを拒否することを意味します。
これはWeb2でもよくある攻撃ですが、今回はスマートコントラクトに対するDoS攻撃を真似てみましょう。

## スマートコントラクトにおけるDOS攻撃

スマートコントラクトは、「KingGame.sol」と「Attack.sol」の2種類を予定しています。
`KingGame.sol`は、王様ゲームの実行に使用され、前回の勝者が送ったETHよりも高いETHを`KingGame.sol`に送ることで、現在のユーザーが勝者となることができる機能を持ちます。
勝者が入れ替わった後、前の勝者はコントラクトに送金したお金が返されます。

`Attack.sol`は、ゲームの現在の勝者になった後、勝とうとするアドレスがより多くのETHを投入しても、他の人に入れ替わることを許さないような攻撃をします。
したがって、`Attack.sol`は`KingGame.sol`をDOS攻撃下に置き、自分が勝者になった後、他のアドレスが勝者になることを拒否します。

## コーディング

次のようなコードで、`KingOfEther`コントラクトを作成してみましょう。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract KingOfEther {
    address public king;
    uint public balance;

    function claimThrone() external payable {
        require(msg.value > balance, "Need to pay more to become the king");

        (bool sent, ) = king.call{value: balance}("");
        require(sent, "Failed to send Ether");

        balance = msg.value;
        king = msg.sender;
    }
}
```

これは非常に基本的なコントラクトで、最後の最高送金者のアドレスと、彼らが送金した値を保存します。
誰もが`claimThrone`関数を呼び出し、`balance`より多くの ETH を送ることができます。
この場合、まず最後の送金者に ETH を送り返そうとし、次にトランザクション呼び出し元を新しい最高送金者としてその ETH 値で設定します。

次に、`Attack`というコントラクトを作成し、以下のコードを記述します。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./KingGame.sol";
// import "./safeKingGame.sol";

contract Attack {
    KingOfEther kingOfEther;

    constructor(KingOfEther _kingOfEther) {
        kingOfEther = KingOfEther(_kingOfEther);
    }

    function attack() public payable {
        kingOfEther.claimThrone{value: msg.value}();
    }
}
```

このコントラクトには`attack()`という関数があり、`KingOfEther`コントラクトの `balance`を呼び出すだけです。
しかし、このコントラクトにはETHを受け取るための`fallback()`関数がないことに注意しましょう。
これについては後で詳しく説明します。

## 実演
[Remix IDE](https://remix.ethereum.org/#optimize=false&runs=200&evmVersion=null&version=builtin)を開きます。

KingGame.solを開いてコンパイルして、デフォルトアドレス (`0x5B38Da6a701c568545dCfcB03FcB875f56beddC4`) でデプロイ。

VALUEの値を `1 Ether` にする。コントラクトのドロップダウンを開く。 `claimThrone`  ボタンを押す。

`balance`ボタンと`king`ボタンを押し、`1000000000000000000` と `0x5B38Da6a701c568545dCfcB03FcB875f56beddC4` が表示されることを確認。

Attack.solを開く。ACCOUNTを `0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2` に変更。KingOfEtherコントラクトのアドレスをコピペしてデプロイ。

VALUEの値を `2 Ether` にする。Attackコントラクトのドロップダウンを開く。 `attack` ボタンを押す。

`balance`ボタンと`king`ボタンを押し,
 `2000000000000000000`、 `0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2` が表示されることを確認。

ACCOUNTを `0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db` に変更。

VALUEの値を `3 Ether` にする。

KingOfEtherコントラクトの `claimThrone` ボタンを押すと、エラーが起こることを確認。

## 原因

`Attack.sol `が `KingGame.sol` をDOS攻撃へと導く様子に注目してください。
まず１人目がKingGame.solの `claimThrone` を呼び出して現在の勝者となり、次に２人目が `Attack.sol` の `attack`関数を使って１人目より多くのETHを送信して現在の勝者となります。
ここで３人目が新しい勝者になろうとすると、KingGame.solコントラクトの12行目の `require` によって、ETHが前の勝者に送り返された場合のみ現在の勝者が変更されることが確認されているので、それを行うことができません。

`Attack.sol`はETHの支払いを受け入れるために必要な`fallback`関数を持っていません。
そのため、`sent`は常に`false`であり、現在の勝者は更新されず、３人目は勝者になることができません。

## 解決策

これを防ぐ方法の1つは、前回勝者用の出金機能を追加することです。

各ユーザーの資金の残高のマッピングを維持し、claimThroneコールでそれを更新しています。
新しいユーザーによって退位させられたユーザーは、withdraw関数を呼び出し、資金を移動させることができます。

出金の有無にかかわらずゲームは継続され、出金していないユーザーの残高もbalances mappingで管理されます。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract KingOfEther {
    address public king;
    uint public balance;
    mapping(address => uint) public balances;

    function claimThrone() external payable {
        require(msg.value > balance, "Need to pay more to become the king");

        balances[king] += balance;

        balance = msg.value;
        king = msg.sender;
    }

    function withdraw() public {
        require(msg.sender != king, "Current king cannot withdraw");

        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
}
```

Attack.solのインポート元をsafeKingGame.solに変更して、同じ処理をします。

`3 Ether`を送る実行が正常に実行されることを確認します。

`balance`ボタンを押すと`3000000000000000000`、`king`ボタンを押すと`0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db`が表示されることを確認。

`balances`ボタンにAttackコントラクトのアドレスを貼って実行すると、`2000000000000000000`と表示される。