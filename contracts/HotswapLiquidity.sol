// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Ownable.sol";
import "./libraries/SafeMath.sol";

contract HotswapFactory is Ownable {
    using SafeMath for uint256;

    address public FFT;
    address public NFT;

    function withdrawFFT() external {}

    function withdrawNFT() external {}
}
