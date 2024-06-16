// SPDX-License-Identifier: BSD-3-Clause
//   ::   .:      ...   :::::::::::: .::::::..::    .   .::::::.  ::::::::::.
//  ,;;   ;;,  .;;;;;;;.;;;;;;;;'''';;;`    `';;,  ;;  ;;;' ;;`;;  `;;;```.;;;
// ,[[[,,,[[[ ,[[     \[[,   [[     '[==/[[[[,'[[, [[, [[' ,[[ '[[, `]]nnn]]'
// "$$$"""$$$ $$$,     $$$   $$       '''    $  Y$c$$$c$P c$$$cc$$$c $$$""
//  888   "88o"888,_ _,88P   88,     88b    dP   "88"888   888   888,888o
//  MMM    YMM  "YMMMMMP"    MMM      "YMmMY"     "M "M"   YMM   ""` YMMMb

pragma solidity ^0.8.25;

import "./Ownable.sol";
import "./HotswapPair.sol";
import "./interfaces/ERC721.sol";
import "./libraries/PreciseMath.sol";
import "./HotswapLiquidity.sol";

contract HotswapControllerBase is HotswapPair {
    address public _collector;
    address public _liquidity;

    uint256 public _price;
    mapping(uint8 => uint256) private _scalars;

    mapping(address => Liquid[]) internal _nftLiquids;
    mapping(address => Liquid[]) internal _fftLiquids;

    uint256 public _fees;

    HotswapLiquidity internal _liq;

    constructor(address nft, address fft) HotswapPair(nft, fft) {
        _collector = msg.sender;
    }

    function nftLiquidity() public view returns (uint256) {
        return _liq.nftBalance();
    }

    function fftLiquidity() public view returns (uint256) {
        return _liq.fftBalance();
    }

    function _updatePrice() internal returns (uint256) {
        _price = _computePrice(nftLiquidity(), fftLiquidity());

        return _price;
    }

    function _computePrice(
        uint256 nft,
        uint256 fft
    ) internal returns (uint256) {
        nft = _scaleUp(nft);
        fft = _normalize(fft);

        return _zerodiv(fft, nft);
    }

    function setCollector(address addr) public onlyOwner {
        _collector = addr;
    }

    function setLiquidity(address addr) public onlyOwner {
        _liquidity = addr;
        _liq = HotswapLiquidity(addr);
        _updatePrice();
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Math
    function _mul(uint256 num1, uint256 num2) internal pure returns (uint256) {
        return PreciseMath.mul(num1, num2);
    }

    function _div(uint256 num1, uint256 num2) internal pure returns (uint256) {
        return PreciseMath.div(num1, num2);
    }

    function _zerodiv(
        uint256 num1,
        uint256 num2
    ) internal pure returns (uint256) {
        return num2 > 0 ? PreciseMath.div(num1, num2) : 0;
    }

    function _scaleUp(uint256 amount) internal pure returns (uint256) {
        return amount * 1e18;
    }

    function _scaleDown(uint256 amount) internal pure returns (uint256) {
        return amount / 1e18;
    }

    function _rescale(uint256 amount) internal pure returns (uint256) {
        return _scaleDown(_scaleUp(amount));
    }

    function _normalize(uint256 amount) internal returns (uint256) {
        return decimals == 1 ? amount : amount * _computeScalar(decimals);
    }

    function _denormalize(uint256 amount) internal returns (uint256) {
        return decimals == 1 ? amount : amount / _computeScalar(decimals);
    }

    function _computeScalar(uint8 decimals) internal returns (uint256 scalar) {
        scalar = _scalars[decimals];

        if (scalar == 0) {
            unchecked {
                _scalars[decimals] = scalar = 10 ** (18 - decimals);
            }
        }
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Data Structures
    struct Liquid {
        uint256 price;
        address depositor;
        uint256 depositedAt;
        uint256 alloc;
        uint256 allocRatio;
        uint256 dVolume;
        bool kind;
        bool claimed;
    }

    struct LiquidData {
        uint256 depositedAt;
        uint256 price;
        uint256 alloc;
        uint256 allocRatio;
        uint256 dVolume;
        bool kind;
        bool claimed;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Events and Errors
    event Swap(uint256 nft, uint256 fft, address user, uint256 price);
    event ChargedFee(uint256 fee);
    event FeeClaimed(address user, uint256 amount);

    error DepositFailed();
    error InvalidWithdrawalRequest();
    error InsufficientLiquidity();
    error InsufficientSwapAmount();
    error InvalidSwapPrice();
    error FeeAlreadyClaimedForSlot();
    error NoReason(uint256 a, uint256 b);

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Util
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
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
}
