// SPDX-License-Identifier: MIT
/// @title Hotswap Controller
// Sources
pragma solidity ^0.8.24;

import "./interfaces/ERC20.sol";
import "./interfaces/ERC721.sol";
import "./HotswapControllerBase.sol";

contract HotswapController is HotswapControllerBase {
    uint256 public _price;
    mapping(address => uint256) internal _nbalances;
    mapping(address => uint256) internal _fbalances;

    address public _collector;
    address public NFT;
    address public FFT;

    ERC20 _fft;
    ERC721Enumerable _nft;

    constructor(address nft, address fft) {
        _collector = msg.sender;
        NFT = nft;
        FFT = fft;

        _fft = ERC20(fft);
        _nft = ERC721Enumerable(nft);
    }

    function getPrice() public returns (uint256) {
        uint256 fBalance = _fft.balanceOf(address(this));
        uint256 nBalance = _nft.balanceOf(address(this));

        // TODO: Consider the decimal points, etc
        _price = fBalance / nBalance;
        // TODO: Update price here
        return _price;
    }

    function depositNFT(uint256 amount) external {
        uint256 tokenId;
        bytes memory data = new bytes(0);

        for (uint256 i = 0; i < amount; i++) {
            tokenId = _nft.tokenOfOwnerByIndex(address(this), i);
            _nft.safeTransferFrom(msg.sender, address(this), tokenId, data);
        }

        _createLiquid(amount, false);
    }

    function depositFFT(uint256 amount) external {
        _createLiquid(amount, true);
    }

    function _createLiquid(uint256 amount, bool kind) private {
        uint256 price = getPrice();

        uint256[] storage userLiquid = _liquidityByUser[msg.sender];
        uint256 index = userLiquid.length;

        Liquid memory lq = Liquid(
            msg.sender,
            block.timestamp,
            kind,
            price,
            0,
            amount,
            0,
            false,
            userLiquid.length
        );

        liquidities.push(lq);
        userLiquid.push(index);
    }
}
