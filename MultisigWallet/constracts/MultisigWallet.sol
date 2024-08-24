// SPDX-License-Identifier: MIT
// author: @0xAA_Science from wtf.academy
pragma solidity ^0.8.21;


/// @title 基于签名的多签钱包，由gnosis safe合约简化而来，学习使用。
contract MultisigWallet {
    //
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public  ownerCount;
    uint256 public  threshold;
    uint256 public  nonce;

    // event
    event ExecutionSuccess(bytes32 txHash);  // 交易成功事件
    event ExecutionFailure(bytes32 txHash);  // 交易失败事件
    


    // 构造函数，初始化owners, isOwner, ownerCount, threshold
    construnctor(
        address[] memeory _owners,
        uint256 _threshold
     ){
        _setupOwners(_owners, _threshold);
    }


    // 从Solidity 0.6.0版本开始，fallback函数已经被弃用，取而代之的是receive函数,
    // 并且从 Solidity 0.8.0 版本开始，如果合约中没有定义 receive() 函数，那么当合约接收到以太币时，将不会执行任何操作，并且发送者将无法取回这些以太币。
    // 因此，为了确保合约能够正确处理接收到的以太币，建议在合约中定义 receive() 函数。
    receive() public payable{}
    

    
    

}