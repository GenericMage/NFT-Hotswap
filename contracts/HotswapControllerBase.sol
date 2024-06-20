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

    uint256 internal _scalar;
    uint256 internal _nftScalar;

    mapping(address => Liquid[]) internal _nftLiquids;
    mapping(address => Liquid[]) internal _fftLiquids;

    uint256 public _fees;

    HotswapLiquidity internal _liq;
    nuint256 FEE_CONSTANT = nuint256.wrap(5e14); // 0.05% => 500000000000000;
    nuint256 MAX_LIQUIDITY_CONSTANT = nuint256.wrap(51e16); // 51% => 510000000000000000;
    nuint256 COLLECTOR_CONSTANT = nuint256.wrap(2e17); // 20% => 200000000000000000

    constructor(address nft, address fft) HotswapPair(nft, fft) {
        _collector = msg.sender;

        _scalar = 10 ** (18 - decimals);
        _nftScalar = 10 ** decimals;
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
    ) internal view returns (uint256) {
        nft = _scaleUp(nft);

        return _denormalize(_zerodiv(fft, nft));
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
    type nuint256 is uint256;

    function _mul(
        uint256 num1,
        nuint256 num2
    ) internal view returns (nuint256) {
        nuint256 nnum1 = _normalize(num1);
        return _mul(nnum1, num2);
    }

    function _mul(
        nuint256 num1,
        uint256 num2
    ) internal view returns (nuint256) {
        nuint256 nnum2 = _normalize(num2);
        return _mul(num1, nnum2);
    }

    function _mul(uint256 num1, uint256 num2) internal view returns (nuint256) {
        nuint256 nnum1 = _normalize(num1);
        nuint256 nnum2 = _normalize(num2);
        return _mul(nnum1, nnum2);
    }

    function _mul(
        nuint256 num1,
        nuint256 num2
    ) internal pure returns (nuint256) {
        return
            nuint256.wrap(
                PreciseMath.mul(nuint256.unwrap(num1), nuint256.unwrap(num2))
            );
    }

    function _div(
        uint256 num1,
        nuint256 num2
    ) internal view returns (nuint256) {
        nuint256 nnum1 = _normalize(num1);
        return _div(nnum1, num2);
    }

    function _div(
        nuint256 num1,
        uint256 num2
    ) internal view returns (nuint256) {
        nuint256 nnum2 = _normalize(num2);
        return _div(num1, nnum2);
    }

    function _div(uint256 num1, uint256 num2) internal view returns (nuint256) {
        nuint256 nnum1 = _normalize(num1);
        nuint256 nnum2 = _normalize(num2);
        return _div(nnum1, nnum2);
    }

    function _div(
        nuint256 num1,
        nuint256 num2
    ) internal pure returns (nuint256) {
        return
            nuint256.wrap(
                PreciseMath.div(nuint256.unwrap(num1), nuint256.unwrap(num2))
            );
    }

    function _zerodiv(
        uint256 num1,
        nuint256 num2
    ) internal view returns (nuint256) {
        nuint256 nnum1 = _normalize(num1);
        return _zerodiv(nnum1, num2);
    }

    function _zerodiv(
        nuint256 num1,
        uint256 num2
    ) internal view returns (nuint256) {
        nuint256 nnum2 = _normalize(num2);
        return _zerodiv(num1, nnum2);
    }

    function _zerodiv(
        uint256 num1,
        uint256 num2
    ) internal view returns (nuint256) {
        nuint256 nnum1 = _normalize(num1);
        nuint256 nnum2 = _normalize(num2);
        return _zerodiv(nnum1, nnum2);
    }

    function _zerodiv(
        nuint256 num1,
        nuint256 num2
    ) internal pure returns (nuint256) {
        uint256 dnum1 = nuint256.unwrap(num1);
        uint256 dnum2 = nuint256.unwrap(num2);

        return nuint256.wrap(dnum2 > 0 ? PreciseMath.div(dnum1, dnum2) : 0);
    }

    function _scaleUp(uint256 amount) internal view returns (uint256) {
        return amount * _nftScalar;
    }

    function _scaleDown(uint256 amount) internal view returns (uint256) {
        return amount / _nftScalar;
    }

    function _normalize(uint256 amount) internal view returns (nuint256) {
        return nuint256.wrap(decimals == 1 ? amount : amount * _scalar);
    }

    function _denormalize(nuint256 amount) internal view returns (uint256) {
        uint256 dAmount = nuint256.unwrap(amount);
        return decimals == 1 ? dAmount : dAmount / _scalar;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Data Structures
    struct Liquid {
        uint256 price;
        address depositor;
        uint256 depositedAt;
        uint256 alloc;
        nuint256 allocRatio;
        uint256 dVolume;
        bool kind;
        bool claimed;
    }

    struct LiquidData {
        uint256 depositedAt;
        uint256 price;
        uint256 alloc;
        nuint256 allocRatio;
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
