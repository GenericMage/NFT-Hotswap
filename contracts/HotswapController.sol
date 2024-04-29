// SPDX-License-Identifier: MIT
/// @title Hotswap Controller
// Sources
pragma solidity ^0.8.24;

import "./interfaces/ERC20.sol";
import "./interfaces/ERC721.sol";
import "./HotswapControllerBase.sol";

contract HotswapController is HotswapControllerBase {
    mapping(address => uint256) internal _nbalances;
    mapping(address => uint256) internal _fbalances;

    uint256 public nftLiquidity; // xLiquid
    uint256 public fftLiquidity; // yLiquid

    uint256 private _nftLiquidityCount;
    uint256 private _fftLiquidityCount;

    uint256 private constant FEE_RATIO_BY_TEN_THOUSAND = 5; // 0.05%

    function getPrice() public returns (uint256) {
        return _computePrice();
    }

    function depositNFT(uint256 amount) external {
        require(
            _liquidity != address(0),
            "Liquidity address is yet to be assigned"
        );

        uint256 tokenId;
        bytes memory data = new bytes(0);

        for (uint256 i = 0; i < amount; i++) {
            tokenId = _nft.tokenOfOwnerByIndex(msg.sender, i);
            _nft.safeTransferFrom(msg.sender, _liquidity, tokenId, data);
        }

        _createLiquid(amount, true);
    }

    function depositFFT(uint256 amount) external {
        bool success = _fft.transferFrom(msg.sender, _liquidity, amount);

        require(success, "Transfer failed");
        _createLiquid(amount, true);
    }

    function _createLiquid(uint256 amount, bool kind) private {
        uint256[] storage userLiquid = _liquidityByUser[msg.sender];
        uint256 index = userLiquid.length;

        Liquid memory lq = Liquid(
            msg.sender,
            block.timestamp,
            kind,
            _price,
            amount,
            false,
            userLiquid.length
        );

        if (kind) {
            _nftLiquidityCount++;
        } else {
            _fftLiquidityCount++;
        }

        liquidities.push(lq);
        userLiquid.push(index);
    }

    function queryLiquid(uint256 index) external {
        return queryLiquidbyDepositor(msg.sender, index);
    }

    function queryLiquidbyDepositor(
        address depositor,
        uint256 index
    ) public returns (LiquidData) {
        uint256[] memory indexes = _liquidityByUser[depositor];
        require(index < indexes.length, "Index out of range");

        uint256 n = indexes[index];

        Liquid memory lq = liquidities[n];

        return
            LiquidData(
                lq.depositor,
                lq.depositedAt,
                lq.depositType,
                lq.price,
                lq.amount,
                lq.claimed
            );
    }

    function getLiquidityCount(bool isFFT) external {
        if (isFFT) {
            return _fftLiquidityCount;
        } else {
            return _nftLiquidityCount;
        }
    }

    function withdrawLiquidity(uint256 index) external {
        address user = msg.sender;
        uint256[] memory userLiquid = _liquidityByUser[user];

        require(index < userLiquid.length, "Index out of range");

        uint256 n = userLiquid[index];
        Liquid memory lq = _liquidity[n];

        uint256 fftLiquid = _fft.balanceOf(_liquidity);
        uint256 nftLiquid = _nft.balanceOf(_liquidity);

        uint256 total = fftLiquid + nftLiquid;
        uint256 nftRatio = total / nftLiquid;
        uint256 fftRatio = total / fftLiquid;

        uint256 fftBalance = lq.amount / fftRatio;
        uint256 nftBalance = (lq.amount / nftRatio) / _price;

        IHotswapLiquidity liq = IHotswapLiquidity(_liquidity);

        liq.withdrawNFT(nftBalance, user);
        liq.withdrawFFT(fftBalance, user);

        _removeLiquidity(lq, n);
    }

    function _removeLiquidity(Liquid lq, uint256 index) {
        uint256 userIndex = lq.userIndex;

        Liquid storage last;
        uint256[] storage userLiquids = _liquidityByUser[userIndex];

        if (_removeItem(userLiquids, userIndex)) {
            last = liquidities[userLiquids[userIndex]];
            last.userIndex = userIndex;
        }

        if (_removeItem(_liquidities, index)) {
            last = liquidities[index];

            userIndex = last.userIndex;
            _liquidityByUser[last.depositor][userIndex] = index;
        }
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

    function _deductFee(uint256 amount) private {
        uint256 fee = (amount * FEE_RATIO_BY_TEN_THOUSAND) / 10_000;

        uint256 collectorFee = fee / 5;
        uint256 remFee = fee - collectorFee;
    }

    function swapNFT(address addr, uint256 amount) {
        uint256 fee = _computeFee(amount);

        amount -= fee;
    }
}
