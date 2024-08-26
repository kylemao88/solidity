## 多签钱包
多签钱包是一种电子钱包，特点是交易被多个私钥持有者（多签人）授权后才能执行：例如钱包由`3`个多签人管理，每笔交易需要至少`2`人签名授权。多签钱包可以防止单点故障（私钥丢失，单人作恶），更加去中心化，更加安全，被很多DAO采用。

Gnosis Safe多签钱包是以太坊最流行的多签钱包，管理近400亿美元资产，合约经过审计和实战测试，支持多链（以太坊，BSC，Polygon等），并提供丰富的DAPP支持。更多信息可以阅读[Gnosis Safe使用教程](https://peopledao.mirror.xyz/nFCBXda8B5ZxQVqSbbDOn2frFDpTxNVtdqVBXGIjj0s)。


## 多签钱包合约
在以太坊上的多签钱包其实是智能合约，属于合约钱包。比如这个极简版多签钱包`MultisigWallet`合约，它的逻辑非常简单：


1. 设置多签人和门槛（链上）：部署多签合约时，我们需要初始化多签人列表和执行门槛（至少n个多签人签名授权后，交易才能执行）。Gnosis Safe多签钱包支持增加/删除多签人以及改变执行门槛，但在我们这次极简版中不考虑这一功能。

2. 创建交易（链下）：一笔待授权的交易包含以下内容（ 这一步也可以考虑优化到链上来进行 ）
    - `to`：目标合约。
    - `value`：交易发送的以太坊数量。
    - `data`：calldata，包含调用函数的选择器和参数。
    - `nonce`：初始为`0`，随着多签合约每笔成功执行的交易递增的值，可以防止签名重放攻击。
    - `chainid`：链id，防止不同链的签名重放攻击。

3. 收集多签签名（链下）：将上一步的交易ABI编码并计算哈希，得到交易哈希，然后让多签人签名，并拼接到一起的到打包签名。对ABI编码和哈希不了解的，可以看WTF Solidity极简教程[第27讲](https://github.com/AmazingAng/WTF-Solidity/blob/main/27_ABIEncode/readme.md)和[第28讲](https://github.com/AmazingAng/WTF-Solidity/blob/main/28_Hash/readme.md)。

    ```solidity
    交易哈希: 0xc1b055cf8e78338db21407b425114a2e258b0318879327945b661bfdea570e66

    多签人A签名: 0x014db45aa753fefeca3f99c2cb38435977ebb954f779c2b6af6f6365ba4188df542031ace9bdc53c655ad2d4794667ec2495196da94204c56b1293d0fbfacbb11c

    多签人B签名: 0xbe2e0e6de5574b7f65cad1b7062be95e7d73fe37dd8e888cef5eb12e964ddc597395fa48df1219e7f74f48d86957f545d0fbce4eee1adfbaff6c267046ade0d81c

    打包签名：
    0x014db45aa753fefeca3f99c2cb38435977ebb954f779c2b6af6f6365ba4188df542031ace9bdc53c655ad2d4794667ec2495196da94204c56b1293d0fbfacbb11cbe2e0e6de5574b7f65cad1b7062be95e7d73fe37dd8e888cef5eb12e964ddc597395fa48df1219e7f74f48d86957f545d0fbce4eee1adfbaff6c267046ade0d81c
    ```

4. 调用多签合约的执行函数，验证签名并执行交易（链上）。对验证签名和执行交易不了解的，可以看WTF Solidity极简教程[第22讲](https://github.com/AmazingAng/WTF-Solidity/blob/main/22_Call/readme.md)和[第37讲](https://github.com/AmazingAng/WTF-Solidity/blob/main/37_Signature/readme.md)。

### 事件

`MultisigWallet`合约有`2`个事件，`ExecutionSuccess`和`ExecutionFailure`，分别在交易成功和失败时释放，参数为交易哈希。

```solidity
    event ExecutionSuccess(bytes32 txHash);    // 交易成功事件
    event ExecutionFailure(bytes32 txHash);    // 交易失败事件
```
