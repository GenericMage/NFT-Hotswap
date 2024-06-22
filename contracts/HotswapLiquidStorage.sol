// SPDX-License-Identifier: BSD-3-Clause
/// @title Hotswap Liquid Storage
//   ::   .:      ...   :::::::::::: .::::::..::    .   .::::::.  ::::::::::.
//  ,;;   ;;,  .;;;;;;;.;;;;;;;;'''';;;`    `';;,  ;;  ;;;' ;;`;;  `;;;```.;;;
// ,[[[,,,[[[ ,[[     \[[,   [[     '[==/[[[[,'[[, [[, [[' ,[[ '[[, `]]nnn]]'
// "$$$"""$$$ $$$,     $$$   $$       '''    $  Y$c$$$c$P c$$$cc$$$c $$$""
//  888   "88o"888,_ _,88P   88,     88b    dP   "88"888   888   888,888o
//  MMM    YMM  "YMMMMMP"    MMM      "YMmMY"     "M "M"   YMM   ""` YMMMb

pragma solidity ^0.8.25;

import "./HotswapPair.sol";

contract HotswapLiquidStorage is HotswapPair {
    modifier onlyAuthorized() {
        require(_auth[msg.sender]);
        _;
    }

    constructor(address nft, address fft) HotswapPair(nft, fft) {
        _auth[_owner] = true;
    }

    mapping(address => bool) internal _auth;
    mapping(address => Liquid[]) public nftLiquids;
    mapping(address => Liquid[]) public fftLiquids;

    function queryLiquid(
        address depositor,
        uint256 index,
        bool isNFT
    )
        public
        view
        returns (
            uint256 alloc,
            nuint256 allocRatio,
            uint256 dVolume,
            bool claimed
        )
    {
        Liquid storage lq = _query(depositor, index, isNFT);
        return (lq.alloc, lq.allocRatio, lq.dVolume, lq.claimed);
    }

    function createLiquid(
        address depositor,
        uint256 alloc,
        nuint256 allocRatio,
        uint256 tVol,
        bool isNFT
    ) external onlyAuthorized {
        Liquid[] storage liquids = isNFT
            ? nftLiquids[depositor]
            : fftLiquids[depositor];

        Liquid memory lq = Liquid(
            block.timestamp,
            alloc,
            allocRatio,
            tVol,
            isNFT,
            false
        );

        liquids.push(lq);
    }

    function claimLiquid(
        address depositor,
        uint256 index,
        bool isNFT
    ) external onlyAuthorized {
        Liquid storage lq = _query(depositor, index, isNFT);
        lq.claimed = true;
    }

    function removeLiquid(
        address depositor,
        uint256 index,
        bool isNFT
    ) external onlyAuthorized {
        Liquid[] storage indexes = isNFT
            ? nftLiquids[depositor]
            : fftLiquids[depositor];

        _removeLQ(indexes, index);
    }

    function _query(
        address depositor,
        uint256 n,
        bool isNFT
    ) private view returns (Liquid storage) {
        Liquid[] storage indexes = isNFT
            ? nftLiquids[depositor]
            : fftLiquids[depositor];

        return indexes[n];
    }

    function _removeLQ(
        Liquid[] storage arr,
        uint256 index
    ) internal returns (bool) {
        uint256 last = arr.length - 1;
        bool isLast = index == last;

        if (!isLast) {
            arr[index] = arr[last];
        }

        arr.pop();
        return !isLast;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Data Structures
    struct Liquid {
        uint256 depositedAt;
        uint256 alloc;
        nuint256 allocRatio;
        uint256 dVolume;
        bool isNFT;
        bool claimed;
    }
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
}
