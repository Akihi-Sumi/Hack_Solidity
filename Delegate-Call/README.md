## 実演
1. Remix IDEで、ディレクトリの下に **HackMe.sol** と **Attack.sol** を作成し、上記のコードをコピペ。
2. それぞれコンパイル。
3. HackMe.solを開く。ACCOUNTはデフォルト(`0x5B38Da6a701c568545dCfcB03FcB875f56beddC4`)を使用。CONTRACTはLibを選択してデプロイ。
4. Libコントラクトのアドレスをコピー。CONTRACTをHackMeに変更し、アドレスを貼り付けてデプロイ。
5. Attack.solを開き、ACCOUNTを別のものに変更。HackMeコントラクトのアドレスをコピペしてデプロイ。
6. HackMeコントラクトのドロップダウンを開く。`owner`ボタンを押し、｢`0x5B38Da6a701c568545dCfcB03FcB875f56beddC4`｣が返ってくることを確認。
7. Attackコントラクトを開く。`attack`ボタンを押す。
8. 再びHackMeコントラクトの`owner`ボタンを押し、アドレスが書き換わっていることを確認。