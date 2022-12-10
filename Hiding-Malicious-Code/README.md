# 悪質な外部コントラクト

暗号の世界では、一見正当な契約書が大きな詐欺の原因であったという話をよく耳にします。
ハッカーはどのようにして、正規の契約書から悪意のあるコードを実行することができるのでしょうか？

## 実演

`Attack.sol` 、`Helper.sol`、`MEC.sol` の3つのコントラクトが存在します。
ユーザーは `MEC.sol` を使って参加資格リストを入力することができ、さらに `Helper.sol` を呼び出して参加資格のあるすべてのユーザーを記録します。

`Attack.sol` は、参加資格者リストを操作できるように設計されているので、見てみましょう。

## コーディング

[Remix IDE](https://remix.ethereum.org/#optimize=false&runs=200&evmVersion=null&version=builtin)を開き、元からある全てのディレクトリとファイルを削除します。

`MEC.sol` を作成します。

```solidity
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "./Helper.sol";

contract MEC {
    Helper helper;
    constructor(address _helper) {
        helper = Helper(_helper);
    }

    function isUserEligible() public view returns(bool) {
        return helper.isUserEligible(msg.sender);
    }

    function addUserToList() public  {
        helper.setUserEligible(msg.sender);
    }

    fallback() external {}
}
```

続いて、`Helper.sol` を作成します。

```solidity
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Helper {
    mapping(address => bool) userEligible;

    function isUserEligible(address user) public view returns(bool) {
        return userEligible[user];
    }

    function setUserEligible(address user) public {
        userEligible[user] = true;
    }

    fallback() external {}
}
```

最後に、`Attack.sol` を作成します。

```solidity
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Attack {
    address owner;
    mapping(address => bool) userEligible;

    constructor() {
        owner = msg.sender;
    }

    function isUserEligible(address user) public view returns(bool) {
        if(user == owner) {
            return true;
        }
        return false;
    }

    function setUserEligible(address user) public {
        userEligible[user] = true;
    }
    
    fallback() external {}
}
```

以下の手順で実行します。

- `Helper.sol`、`Attack.sol`、`MEC.sol`をコンパイルする。

正常版

- ACCOUNTがデフォルトになっていることを確認し、`Helper.sol`をデプロイ。そのまま、`Helper`コントラクトのアドレスをコピペして`MEC.sol`をデプロイ。

- ACCOUNTを3番目のものに切り替えて、そのアドレスをコピー。Helperコントラクトの`setUserEligible`に貼り付けてボタンを押す。`isUserEligible`ボタンを押して`true`が返ってくることを確認。

- MECコントラクトの`addUserToList`ボタンを押す。続いて `isUserEligible`ボタンを押して`true`が返ってくることを確認。

異常版

- ACCOUNTを2番目のものに切り替えて、`Attack.sol`をデプロイ。そのまま、`Attack`コントラクトのアドレスをコピペして`MEC.sol`をデプロイ。

- ACCOUNTを3番目のものに切り替えて、そのアドレスをコピー。Helperコントラクトの`setUserEligible`に貼り付けてボタンを押す。`isUserEligible`ボタンを押して`false`が返ってくることを確認。

- MECコントラクトの`addUserToList`ボタンを押す。続いて `isUserEligible`ボタンを押して`false`が返ってくることを確認。

## 原因

`Attack.sol` は、`Helper.sol` と同じABIを生成することに気づきます。
これは、ABIには、パブリック変数、関数、イベントに対する関数定義しか含まれないからです。
つまり、`Attack.sol` は `Helper.sol` と同じようにタイプキャストすることができるのです。

`Attack.sol` は `Helper.sol` としてタイプキャストできるので、悪意のある所有者は、`Helper.sol` の代わりに `Attack.sol` のアドレスを持つ `MEC.sol` を展開し、ユーザーは、彼が本当にEligibility listを作成するために `Helper.sol` を使っていると信じることができるのである。

この場合、詐欺は次のように行われます。
詐欺師はまず、`Attack.sol`のアドレスを持つ `MEC.sol` をデプロイします。
次に、ユーザが `addUserToList`関数を使用して適格性リストを入力すると、この関数のコードは`Helper.sol`と`Attack.sol`で同じなのでうまく動作します。

なぜなら、この関数は `Attack.sol` の `isUserEligible` 関数を呼び出すので、常に`false`を返すからです。
この関数は、オーナー自身を除いて常に`false`を返すので、このようなことは起こらないはずでした。

## 予防策

- 外部コントラクトのアドレスを公開し、すべてのユーザーがコードを見ることができるようにします

- コンストラクタ内でコントラクトにアドレスをタイプキャストするのではなく、 新しいコントラクトを作成します。
つまり、`Helper(_helper)`のように `_helper` のアドレスをヘルパーのコントラクトに型キャストするのではなく、 `new Helper()` を使って新しいヘルパーのコントラクトを明示的に作成する。

```solidity
    Heper public helper;
        constructor(address _helper) {
        helper = new Helper();
    }
```