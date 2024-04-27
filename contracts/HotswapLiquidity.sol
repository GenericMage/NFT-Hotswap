// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Ownable.sol";
import "./libraries/SafeMath.sol";
import "./interfaces/ERC20.sol";
import "./interfaces/ERC721.sol";
import "./HotswapBase.sol";

contract HotswapLiquidity is HotswapBase {
    using SafeMath for uint256;

    constructor(address nft, address fft) {
        NFT = nft;
        FFT = fft;

        _nft = ERC721Enumerable(nft);
        _fft = ERC20(fft);
    }

    address public NFT;
    address public FFT;
    address public Controller;

    ERC20 _fft;
    ERC721Enumerable _nft;

    modifier onlyAuthorized() {
        require(msg.sender == _owner || msg.sender == Controller);
        _;
    }

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
        Controller = addr;
    }
}
