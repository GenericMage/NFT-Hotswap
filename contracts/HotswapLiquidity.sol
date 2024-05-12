// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./Ownable.sol";
import "./libraries/SafeMath.sol";
import "./interfaces/ERC20.sol";
import "./interfaces/ERC721.sol";
import "./HotswapPair.sol";

contract HotswapLiquidity is HotswapPair {
    using SafeMath for uint256;

    address public controller;

    modifier onlyAuthorized() {
        require(msg.sender == _owner || msg.sender == controller);
        _;
    }

    constructor(address nft, address fft) HotswapPair(nft, fft) {}

    function withdrawFFT(uint256 amount, address dest) external onlyAuthorized {
        require(_fft.transfer(dest, amount), "Withdrawal failed");
    }

    function withdrawNFT(uint256 amount, address dest) external onlyAuthorized {
        uint256 tokenId;
        bytes memory data = new bytes(0);

        for (uint256 i = 0; i < amount; i++) {
            tokenId = _nft.tokenOfOwnerByIndex(address(this), i);
            _nft.safeTransferFrom(address(this), dest, tokenId, data);
        }
    }

    function setController(address addr) external onlyOwner {
        controller = addr;
    }
}
