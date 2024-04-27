// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Ownable.sol";

contract HotswapBase is Ownable {
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

    event NativeTransferred(uint256 amount, address targetAddr);
}
