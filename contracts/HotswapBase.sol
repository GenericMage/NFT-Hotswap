// SPDX-License-Identifier: BSD-3-Clause
//   ::   .:      ...   :::::::::::: .::::::..::    .   .::::::.  ::::::::::.
//  ,;;   ;;,  .;;;;;;;.;;;;;;;;'''';;;`    `';;,  ;;  ;;;' ;;`;;  `;;;```.;;;
// ,[[[,,,[[[ ,[[     \[[,   [[     '[==/[[[[,'[[, [[, [[' ,[[ '[[, `]]nnn]]'
// "$$$"""$$$ $$$,     $$$   $$       '''    $  Y$c$$$c$P c$$$cc$$$c $$$""
//  888   "88o"888,_ _,88P   88,     88b    dP   "88"888   888   888,888o
//  MMM    YMM  "YMMMMMP"    MMM      "YMmMY"     "M "M"   YMM   ""` YMMMb

pragma solidity ^0.8.25;

import "./Ownable.sol";
import "./libraries/SafeMath.sol";

contract HotswapBase is Ownable {
    using SafeMath for uint256;

    function _transferNative(
        address payable to,
        uint256 amount
    ) internal returns (bool) {
        if (to.send(amount)) {
            emit NativeTransferred(amount, to);
            return true;
        }

        return false;
    }

    function _removeItem(
        uint256[] storage arr,
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

    function _removeItem(
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

    struct Liquid {
        address depositor;
        uint256 depositedAt;
        uint256 price;
        uint256 nftAlloc;
        uint256 fftAlloc;
        bool claimed;
        uint256 userIndex;
        bool initialKind;
        uint256 initialAlloc;
    }

    struct LiquidData {
        address depositor;
        uint256 depositedAt;
        uint256 price;
        uint256 nftAlloc;
        uint256 fftAlloc;
        bool claimed;
    }

    event NativeTransferred(uint256 amount, address targetAddr);
}
