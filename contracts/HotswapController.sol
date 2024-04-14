pragma solidity ^0.8.24;

import "./HotswapControllerBase.sol";

contract HotswapController is HotswapControllerBase {
    uint256 public _price;
    mapping(address => uint256) internal _nbalances;
    mapping(address => uint256) internal _fbalances;

    address public _collector;

    constructor(address nft, address fft) {}

    function getPrice() external returns (uint256) {
        // TODO: Update price here
        return _price;
    }

    // function swapNFT()

    function depositNFT() external {}
}
