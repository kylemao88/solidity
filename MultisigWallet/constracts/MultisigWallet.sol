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
    

    // 从Solidity 0.6.0版本开始，fallback函数已经被弃用，取而代之的是receive函数,
    // 并且从 Solidity 0.8.0 版本开始，如果合约中没有定义 receive() 函数，那么当合约接收到以太币时，将不会执行任何操作，并且发送者将无法取回这些以太币。
    // 因此，为了确保合约能够正确处理接收到的以太币，建议在合约中定义 receive() 函数。
    receive() public payable{}


    // 构造函数，初始化owners, isOwner, ownerCount, threshold
    construnctor(
        address[] memeory _owners,
        uint256 _threshold
     ){
        _setupOwners(_owners, _threshold);
    }

    /// @dev 初始化owners, isOwner, ownerCount,threshold 
    /// @param _owners: 多签持有人数组
    /// @param _threshold: 多签执行门槛，至少有几个多签人签署了交易
    function _setupOwners(address[] memory _owners, uint256 memory _threshold ) internal {
        // threshold 没被初始化过，防止重复调用
        require( threshold ==0, "already setup owners" );
        // 多签执行门槛 小于 多签人数
        require( _threshold <= _owners.length, "_threshold is too large");
        // 多签执行门槛至少为1
        require( _threshold > =1, "invalid _threshold")

        for ( uint i = 0; i< _owners.length; i++ ) {
            //
            address owner = _owners[i]

            // 多签人不能是0地址，本合约地址，不能重复
            require( onwer!= address(0) && owner != address(this)  &&  !isOwner[owner], "invalid owner address" )
            owners.push(owner);
            isOwner[owner] = true;
        }
        ownerCount = owners.length;
        threshold = _threshold;
    }

    /// @dev 在收集足够的多签签名后，执行交易
    /// @param  to 目标合约地址
    /// @param value msg.value，支付的以太坊
    /// @param data calldata
    /// @param signatures 打包的签名，对应的多签地址由小到达，方便检查。 ({bytes32 r}{bytes32 s}{uint8 v}) (第一个多签的签名, 第二个多签的签名 ... )
    function execTransaction(
          address to,
        uint256 value,
        bytes memory data,
        bytes memory signatures
    ) public payable virtual return (bool success) {
        // 编码交易数据，计算hash-msg
        bytes32 txHash = encodeTransactionData(to,value,data,nonce, block.chainid);
        // 增加nonce
        nonce++;
        // 检查签名
        checkSignatures(txHash, signatures);

        // 执行转账交易
        (success, )= to.call{value: value}(data);
        require(success, " to.call fail")

        //
        if success{
            emit ExecutionSuccess(txHash);
        } else{
            emit ExecutionFailure(txHash);
        }
    } 


    /// @dev 编码交易数据
    /// @param to 目标合约地址
    /// @param value msg.value，支付的以太坊
    /// @param data calldata
    /// @param _nonce 交易的nonce.
    /// @param chainid 链id
    /// @return 交易哈希bytes.
    function encodeTransactionData(
        address to,
        uint256 value,
        bytes memory data,
        uint256 _nonce,
        uint256 chainid
    ) public pure return (bytes32) {
        bytes32 safaTxHash =
        keccak256(
            abi.encode(
            to,
            value,
            keccak256(data),
            _nonce,
            chainid
            )
        );
        return safaTxHash;
    }

    
    /// @dev 检查签名和交易数据是否对应。如果是无效签名，交易会revert
    function checkSignatures( bytes32 dataHash, bytes memory signatures) public view {
        // 读取多签执行门槛
        require( threshold > 0, "invalid threshold" );
        // 检查签名长度足够长
        require( signatures.length >= threshold *65, "invalid signatures"  );

        // 通过一个循环，检查收集的签名（因为多签，有多个）是否有效
        // 大概思路：
        // 1. 用ecdsa先验证签名是否有效
        // 2. 检查 currentOwner > lastOwner 确定签名来自不同多签（多签地址递增）
        // 3. 检查 isOwner[currentOwner] 确定签名者多多签持有人
        address lastOwner = address(0)
        address currOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        for( uint i= 0; i< threshold; i++ ) {
            (v, r, s) = signatureSplit(signatures, i);

            // 利用ecrecover 验证签名并恢复签名者地址
            currOwner = ecrecover(  keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash )), v, r, s  );
            require(  currOwner > lastOwner && isOwner[currOwner], "invalid currOwner from ecrecover" );
            lastOwner = currOwner;
        }

    }
 

    /// @dev 将单个签名从打包签名中分离出来
    /// @param signatures  打包的签名
    /// @param pos 要读取的多签index
    function signatureSplit( bytes memory signatures, uint256 pos )
        internal
        pure
        return( uint8 v, bytes32 r, bytes32 s ){
        // 签名格式 : {bytes32 r}{bytes32 s}{uint8 v}
        assembly{
            /**
            这里的 0x41 是一个魔法数字，它的来源与 Ethereum 签名数据的存储方式有关。
            在 Ethereum 中，每个签名占用 65 个字节（bytes32 r 占用 32 字节，bytes32 s 占用 32 字节，uint8 v 占用 1 字节）。但是，在实际存储时，v 值可能会占用 2 个字节（当 v 的值为 27 或 28 时，表示签名使用了扩展的 v 值，即 v 实际上是一个 uint256 类型的值，但只使用了低 8 位）。为了容纳这种可能的扩展，每个签名在字节数组中实际上占用了 66 个字节。
            因此，每个签名之间的间距是 66 字节。在代码中，这个间距被表示为 0x41（十进制的 65）。所以，mul(0x41, pos) 计算的是第 pos 个签名在字节数组中的起始位置。
             */
            let signaturePos :=  mul(0x41, pos)
            r := mload( add(signatures, add(signaturePos, 0x20)))
            s := mload( add(signatures, add(signaturePos, 0x40)))
            v := and(mload( add(signatures, add(signaturePos, 0x41))), oxff)
        }
    }

    

}