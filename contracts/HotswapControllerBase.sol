// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Ownable.sol";
import "./interfaces/ERC721.sol";
import "./libraries/SafeMath.sol";
import "./HotswapLiquidity.sol";

interface IHotswapController {
    function setCollector(address addr) external;
    function setLiquidity(address addr) external;
}

interface IHotswapLiquidity {
    function setController(address addr) external;

    function withdrawFFT(uint256 amount, address dest) external;
    function withdrawNFT(uint256 amount, address dest) external;
}

contract HotswapControllerBase is Ownable, IHotswapController {
    using SafeMath for uint256;

    address public NFT;
    address public FFT;
    address public _collector;
    address public _liquidity;

    uint256 public _price;

    internal ERC20 _fft;
    internal ERC721Enumerable _nft;

    mapping(address => uint256[]) internal _liquidityByUser;
    
    Liquid[] public _liquidities;

    constructor(address nft, address fft) {
        _collector = msg.sender;
        NFT = nft;
        FFT = fft;

        _fft = ERC20(fft);
        _nft = ERC721Enumerable(nft);
    }

    function _computePrice() private {
        uint256 fBalance = _fft.balanceOf(_liquidity);
        uint256 nBalance = _nft.balanceOf(_liquidity);

        // TODO: Consider the decimal points, etc
        _price = fBalance / nBalance;
        return _price;
    }

    function setCollector(address addr) external onlyOwner {
        _collector = addr;
    }

    function setLiquidity(address addr) external onlyOwner {
        _liquidity = addr;
        _computePrice();
    }

    struct Liquid {
        address depositor;
        uint256 depositedAt;
        bool depositType;
        uint256 price;
        uint256 amount;
        bool claimed;
        uint256 userIndex;
    }

    struct LiquidData {
        address depositor;
        uint256 depositedAt;
        bool depositType;
        uint256 price;
        uint256 amount;
        bool claimed;
    }
}
