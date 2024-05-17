// SPDX-License-Identifier: BSD-3-Clause
/// @title Hotswap Controller
//   ::   .:      ...   :::::::::::: .::::::..::    .   .::::::.  ::::::::::.
//  ,;;   ;;,  .;;;;;;;.;;;;;;;;'''';;;`    `';;,  ;;  ;;;' ;;`;;  `;;;```.;;;
// ,[[[,,,[[[ ,[[     \[[,   [[     '[==/[[[[,'[[, [[, [[' ,[[ '[[, `]]nnn]]'
// "$$$"""$$$ $$$,     $$$   $$       '''    $  Y$c$$$c$P c$$$cc$$$c $$$""
//  888   "88o"888,_ _,88P   88,     88b    dP   "88"888   888   888,888o
//  MMM    YMM  "YMMMMMP"    MMM      "YMmMY"     "M "M"   YMM   ""` YMMMb

pragma solidity ^0.8.25;

import "./interfaces/ERC20.sol";
import "./interfaces/ERC721.sol";
import "./HotswapControllerBase.sol";

contract HotswapController is HotswapControllerBase {
    uint256 public nftLiquidity; // xLiquid
    uint256 public fftLiquidity; // yLiquid

    uint256 private _nftLiquidityCount;
    uint256 private _fftLiquidityCount;

    uint256 private _cumulativeTimestamp;

    uint256 private constant FEE = 5e14; // 0.05% [Normalized]
    uint256 private constant COLLECTOR_FEE_RATIO = 5e18; // 1/5 i.e 0.2, 20%

    constructor(address nft, address fft) HotswapControllerBase(nft, fft) {}

    function depositNFT(uint256 amount) external {
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
        if (!_fft.transferFrom(msg.sender, _liquidity, amount)) {
            revert DepositFailed();
        }

        _createLiquid(amount, true);
    }

    function claimFees() external {
        address targetAddr = msg.sender;
        uint256[] memory nLiquids = _liquidityByUser[targetAddr];

        uint256 n;
        Liquid storage liquid;

        uint256 totalLiquidity = _normalize(_liq.fftBalance(), decimals);

        uint256 nfees = 0;

        for (uint256 i = 0; i < nLiquids.length; i++) {
            n = nLiquids[i];
            liquid = _liquids[n];

            if (!liquid.claimed) {
                uint256 timeRatio = _div(
                    liquid.depositedAt,
                    _cumulativeTimestamp
                );
                uint256 valueRatio = _div(liquid.fftAlloc, totalLiquidity);

                liquid.claimed = true;

                nfees += _div(timeRatio + valueRatio, 2e18); // (timeRatio + valueRatio) / 2;
            }
        }

        if (nfees <= 0) {
            return;
        }

        uint256 fees = _denormalize(nfees, decimals);
        _liq.withdrawFFT(fees, targetAddr);
    }

    function _createLiquid(uint256 amount, bool kind) private {
        uint256[] storage userLiquid = _liquidityByUser[msg.sender];
        uint256 index = userLiquid.length;

        uint256 nftAmount = 0;
        uint256 fftAmount = 0;

        if (kind) {
            nftAmount = amount;
        } else {
            fftAmount = _normalize(amount, decimals);
        }

        uint256 timestamp = block.timestamp;
        _cumulativeTimestamp += timestamp;

        Liquid memory lq = Liquid(
            msg.sender,
            timestamp,
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

        _liquids.push(lq);
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
        uint256 n = indexes[index];

        Liquid memory lq = _liquids[n];

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
        return isFFT ? _fftLiquidityCount : _nftLiquidityCount;
    }

    function withdrawLiquidity(uint256 index) external {
        address user = msg.sender;
        uint256[] memory userLiquid = _liquidityByUser[user];

        if (index >= userLiquid.length) {
            revert InvalidWithdrawalRequest();
        }

        uint256 n = userLiquid[index];
        Liquid memory lq = _liquids[n];

        uint256 nftAlloc = _normalize(lq.nftAlloc, DEFAULT_DECIMALS);
        uint256 fftAlloc = lq.fftAlloc;

        uint256 total = nftAlloc + fftAlloc;
        uint256 nftRatio = _div(total, nftAlloc);
        uint256 fftRatio = _div(total, fftAlloc);

        uint256 nftBalance = _div(nftAlloc, nftRatio);
        nftBalance = _div(nftBalance, _price);
        uint256 fftBalance = _div(fftAlloc, fftRatio);

        uint256 dnft = _denormalize(nftBalance, DEFAULT_DECIMALS);
        uint256 dfft = _denormalize(fftBalance, decimals);

        _liq.withdrawNFT(dnft, user);
        _liq.withdrawFFT(dfft, user);

        _removeLiquidity(lq, n);
        _cumulativeTimestamp -= lq.depositedAt;
    }

    function _removeLiquidity(Liquid memory lq, uint256 index) private {
        uint256 userIndex = lq.userIndex;

        Liquid storage last;
        uint256[] storage userLiquids = _liquidityByUser[msg.sender];

        if (_removeItem(userLiquids, userIndex)) {
            last = _liquids[userLiquids[userIndex]];
            last.userIndex = userIndex;
        }

        if (_removeItem(_liquids, index)) {
            last = _liquids[index];

            userIndex = last.userIndex;
            _liquidityByUser[last.depositor][userIndex] = index;
        }
    }

    function _deductFee(uint256 amount) private returns (uint256) {
        uint256 nFee = _mul(amount, FEE);

        uint256 nCollectorFee = _div(nFee, COLLECTOR_FEE_RATIO);
        uint256 nRemFee = nFee - nCollectorFee;

        uint256 collectorFee = _denormalize(nCollectorFee, decimals);
        uint256 remFee = _denormalize(nRemFee, decimals);

        bool success = _fft.transfer(_collector, collectorFee);
        require(success);
        success = _fft.transfer(address(this), remFee);
        require(success);

        _fees += nRemFee;

        return nFee;
    }

    function swapNFT(uint256 amount) external {
        uint256[] memory indexes = _liquidityByUser[msg.sender];

        uint256 price = _price;

        uint256 nAmount = _normalize(amount, decimals);

        uint256 fftAmount = _mul(nAmount, price);

        // TODO: Should any extra FFTs in this calculation be stored as fees?
        fftAmount -= _deductFee(fftAmount);
        uint256 nnft = _div(fftAmount, price);
        uint256 nftAmount = _denormalize(nnft, DEFAULT_DECIMALS);

        bool success;
        uint256 index;

        for (uint256 i = indexes.length; i > 0 && nftAmount > 0; i--) {
            (success, index) = _findSuitableLiquid(false);

            nftAmount = _swapNFTLiquid(indexes[i - 1], index, nftAmount, price);
        }

        if (nftAmount > 0) {
            revert InsufficientLiquidity();
        }
    }

    function swapFFT(uint256 amount) external {
        Liquid storage source;
        Liquid storage target;

        uint256[] memory indexes = _liquidityByUser[msg.sender];
        uint256 price = _price;

        uint256 nAmount = _normalize(amount, decimals);

        uint256 fftAmount = nAmount - _deductFee(nAmount);

        bool success;
        uint256 index;

        for (uint256 i = indexes.length; i > 0 && fftAmount > 0; i--) {
            (success, index) = _findSuitableLiquid(true);
            fftAmount = _swapFFTLiquid(indexes[i - 1], index, fftAmount, price);
        }

        if (fftAmount > 0) {
            revert InsufficientLiquidity();
        }
    }

    function _swapNFTLiquid(
        uint256 nSource,
        uint256 nTarget,
        uint256 targetAmount,
        uint256 price
    ) private returns (uint256) {
        uint256 swapAmount;

        Liquid storage source = _liquids[nSource];
        Liquid storage target = _liquids[nTarget];

        if (source.nftAlloc <= targetAmount) {
            swapAmount = source.nftAlloc;
        } else {
            swapAmount = targetAmount;
        }

        source.nftAlloc -= swapAmount;
        targetAmount -= swapAmount;

        source.fftAlloc += _normalize(_mul(swapAmount, price), decimals);
        target.nftAlloc += swapAmount;

        return targetAmount;
    }

    function _swapFFTLiquid(
        uint256 nSource,
        uint256 nTarget,
        uint256 targetAmount,
        uint256 price
    ) private returns (uint256) {
        Liquid storage source = _liquids[nSource];
        Liquid storage target = _liquids[nTarget];
        uint256 alloc = source.fftAlloc;

        uint256 swapAmount = alloc <= targetAmount ? alloc : targetAmount;

        source.fftAlloc -= swapAmount;
        targetAmount -= swapAmount;

        target.fftAlloc += swapAmount;
        source.nftAlloc += _denormalize(
            _div(swapAmount, price),
            DEFAULT_DECIMALS
        );

        return targetAmount;
    }

    function _findSuitableLiquid(
        bool isNFT
    ) private view returns (bool success, uint256 index) {
        Liquid memory liquid;

        uint256 j;

        for (j = _liquids.length; j > 0 && !success; j--) {
            index = j - 1;

            liquid = _liquids[index];

            if (!isNFT && liquid.fftAlloc > 0) {
                success = true;
            } else if (isNFT && liquid.nftAlloc > 0) {
                success = true;
            }
        }
    }
}
