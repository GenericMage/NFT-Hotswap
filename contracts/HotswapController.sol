// SPDX-License-Identifier: BSD-3-Clause
/// @title Hotswap Controller
// Sources
pragma solidity ^0.8.25;

import "./interfaces/ERC20.sol";
import "./interfaces/ERC721.sol";
import "./HotswapControllerBase.sol";

contract HotswapController is HotswapControllerBase {
    uint256 public nftLiquidity; // xLiquid
    uint256 public fftLiquidity; // yLiquid

    uint256 private _nftLiquidityCount;
    uint256 private _fftLiquidityCount;

    uint256 private constant FEE_RATIO_BY_TEN_THOUSAND = 5; // 0.05%

    constructor(address nft, address fft) HotswapControllerBase(nft, fft) {}

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

        // TODO: Start based on current balance
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

        uint256 nftAmount = 0;
        uint256 fftAmount = 0;

        if (kind) {
            nftAmount = amount;
        } else {
            fftAmount = amount;
        }

        Liquid memory lq = Liquid(
            msg.sender,
            block.timestamp,
            _price,
            nftAmount,
            fftAmount,
            false,
            userLiquid.length
        );

        if (kind) {
            _nftLiquidityCount++;
        } else {
            _fftLiquidityCount++;
        }

        _liquidities.push(lq);
        userLiquid.push(index);
    }

    function queryLiquid(
        uint256 index
    ) external view returns (LiquidData memory) {
        return queryLiquidbyDepositor(msg.sender, index);
    }

    function queryLiquidbyDepositor(
        address depositor,
        uint256 index
    ) public view returns (LiquidData memory) {
        uint256[] memory indexes = _liquidityByUser[depositor];
        require(index < indexes.length, "Index out of range");

        uint256 n = indexes[index];

        Liquid memory lq = _liquidities[n];

        return
            LiquidData(
                lq.depositor,
                lq.depositedAt,
                lq.price,
                lq.nftAlloc,
                lq.fftAlloc,
                lq.claimed
            );
    }

    function getLiquidityCount(bool isFFT) external view returns (uint256) {
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
        Liquid memory lq = _liquidities[n];

        uint256 nftAlloc = lq.nftAlloc;
        uint256 fftAlloc = lq.fftAlloc;

        uint256 total = nftAlloc + fftAlloc;
        uint256 nftRatio = total / nftAlloc;
        uint256 fftRatio = total / fftAlloc;

        // TODO: Revist and re-eval
        IHotswapLiquidity liq = IHotswapLiquidity(_liquidity);

        uint256 nftBalance = (nftAlloc / nftRatio) / _price;
        uint256 fftBalance = fftAlloc / fftRatio;

        liq.withdrawNFT(nftBalance, user);
        liq.withdrawFFT(fftBalance, user);

        _removeLiquidity(lq, n);
    }

    function _removeLiquidity(Liquid memory lq, uint256 index) private {
        uint256 userIndex = lq.userIndex;

        Liquid storage last;
        uint256[] storage userLiquids = _liquidityByUser[msg.sender];

        if (_removeItem(userLiquids, userIndex)) {
            last = _liquidities[userLiquids[userIndex]];
            last.userIndex = userIndex;
        }

        if (_removeItem(_liquidities, index)) {
            last = _liquidities[index];

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

    function _removeItem(
        uint256[] storage arr,
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

    function _deductFee(uint256 amount) private returns (uint256) {
        uint256 fee = (amount * FEE_RATIO_BY_TEN_THOUSAND) / 10_000;

        uint256 collectorFee = fee / 5;
        uint256 remFee = fee - collectorFee;

        bool success = _fft.transfer(_collector, collectorFee);
        require(success);
        success = _fft.transfer(address(this), remFee);
        require(success);

        _fees += remFee;

        return fee;
    }

    function swapNFT(uint256 amount) external {
        Liquid storage source;
        Liquid storage target;

        uint256[] memory indexes = _liquidityByUser[msg.sender];

        uint256 price = _price;

        uint256 fftAmount = amount * price;

        fftAmount -= _deductFee(fftAmount);
        uint256 nftAmount = fftAmount / price;

        bool success;
        uint256 index;

        uint256 i;
        uint256 j;

        for (j = indexes.length; j > 0 && nftAmount > 0; j--) {
            i = j - 1;
            source = _liquidities[indexes[i]];

            (success, index) = _findSuitableLiquid(false);
            target = _liquidities[index];

            nftAmount = _swapNFTLiquid(source, target, nftAmount, price);
        }

        require(nftAmount == 0, "Insufficient liquidity");
    }

    function swapFFT(uint256 amount) external {
        Liquid storage source;
        Liquid storage target;

        uint256[] memory indexes = _liquidityByUser[msg.sender];
        uint256 price = _price;

        uint256 targetAmount = _deductFee(amount);

        uint256 fftAmount = targetAmount;

        bool success;
        uint256 index;

        uint256 i;
        uint256 j;

        for (j = indexes.length; j > 0 && fftAmount > 0; j--) {
            i = j - 1;
            source = _liquidities[indexes[i]];

            (success, index) = _findSuitableLiquid(true);
            target = _liquidities[index];

            fftAmount = _swapFFTLiquid(source, target, fftAmount, price);
        }

        require(fftAmount == 0, "Insufficient liquidity");
    }

    function _swapNFTLiquid(
        Liquid storage source,
        Liquid storage target,
        uint256 targetAmount,
        uint256 price
    ) private returns (uint256) {
        uint256 swapAmount;

        if (source.nftAlloc <= targetAmount) {
            swapAmount = source.nftAlloc;
        } else {
            swapAmount = targetAmount;
        }

        source.nftAlloc -= swapAmount;
        targetAmount -= swapAmount;

        source.fftAlloc += swapAmount * price;
        target.nftAlloc += swapAmount;

        return targetAmount;
    }

    function _swapFFTLiquid(
        Liquid storage source,
        Liquid storage target,
        uint256 targetAmount,
        uint256 price
    ) private returns (uint256) {
        uint256 alloc = source.fftAlloc;

        uint256 swapAmount = alloc <= targetAmount ? alloc : targetAmount;

        source.fftAlloc -= swapAmount;
        targetAmount -= swapAmount;

        source.nftAlloc += swapAmount / price;
        target.fftAlloc += swapAmount;

        return targetAmount;
    }

    function _findSuitableLiquid(
        bool isNFT
    ) private view returns (bool success, uint256 index) {
        Liquid memory liquid;

        uint256 j;

        for (j = _liquidities.length; j > 0 && !success; j--) {
            index = j - 1;

            liquid = _liquidities[index];

            if (!isNFT && liquid.fftAlloc > 0) {
                success = true;
            } else if (isNFT && liquid.nftAlloc > 0) {
                success = true;
            }
        }
    }
}
