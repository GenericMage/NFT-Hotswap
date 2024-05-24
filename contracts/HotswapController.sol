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
    uint256 private _nftLiquidityCount;
    uint256 private _fftLiquidityCount;

    uint256 private _cumulativeTimestamp;

    uint256 private constant FEE = 5e14; // 0.05% [Normalized]
    uint256 private constant COLLECTOR_FEE_RATIO = 5e18; // 1/5 i.e 0.2, 20%

    uint256 private _x;

    constructor(address nft, address fft) HotswapControllerBase(nft, fft) {}

    function nftLiquidity() external view returns (uint256) {
        return _liq.nftBalance();
    }

    function fftLiquidity() external view returns (uint256) {
        return _liq.fftBalance();
    }

    function depositNFT(uint256 amount) external {
        _deposit(amount, true);
        _createLiquid(amount, true);
    }

    function depositFFT(uint256 amount) external {
        _deposit(amount, false);
        _createLiquid(amount, false);
    }

    function _deposit(uint256 amount, bool isNFT) private {
        if (amount <= 0) {
            revert DepositFailed();
        }

        if (isNFT) {
            uint256 tokenId;
            bytes memory data = new bytes(0);

            // TODO: Start based on current balance
            for (uint256 i = 0; i < amount; i++) {
                tokenId = _nft.tokenOfOwnerByIndex(msg.sender, i);
                _nft.safeTransferFrom(msg.sender, _liquidity, tokenId, data);
            }
        } else if (!_fft.transferFrom(msg.sender, _liquidity, amount)) {
            revert DepositFailed();
        }
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
        uint256 price = updatePrice();

        if (kind) {
            nftAmount = _scaleUp(amount);
        } else {
            fftAmount = _normalize(amount, decimals);
        }

        uint256 timestamp = block.timestamp;
        _cumulativeTimestamp += timestamp;

        Liquid memory lq = Liquid(
            msg.sender,
            timestamp,
            price,
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
        // address user = msg.sender;
        uint256[] memory userLiquid = _liquidityByUser[msg.sender];

        if (index >= userLiquid.length) {
            revert InvalidWithdrawalRequest();
        }

        uint256 n = userLiquid[index];
        Liquid memory lq = _liquids[n];
        uint256 price = lq.price > 0 ? lq.price : _price;

        uint256 nftAlloc = lq.nftAlloc;
        uint256 fftAlloc = lq.fftAlloc;

        uint256 total = nftAlloc + fftAlloc;
        uint256 nftRatio = _zerodiv(total, nftAlloc);
        uint256 fftRatio = _zerodiv(total, fftAlloc);

        uint256 nftBalance = _zerodiv(nftAlloc, nftRatio);
        nftBalance = _zerodiv(nftBalance, price);

        uint256 fftBalance = fftRatio > 0 ? _zerodiv(fftAlloc, fftRatio) : 0;

        uint256 dnft = _scaleDown(nftBalance);
        uint256 dfft = _denormalize(fftBalance, decimals);

        _liq.withdrawNFT(dnft, msg.sender);
        _liq.withdrawFFT(dfft, msg.sender);

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

    function _determineCost(
        uint256 nft,
        uint256 fft
    ) private view returns (uint256 nftAmount, uint256 fftAmount, uint256 fee) {
        uint256 price = _price;

        if (price == 0) {
            revert InvalidSwapPrice();
        }

        nftAmount = nft;
        fftAmount = fft;

        if (nftAmount == 0) {
            nftAmount = _rescale(_div(fftAmount, _price));
        } else {
            nftAmount = _scaleUp(nftAmount);
            fftAmount = _mul(nftAmount, _price);
        }

        fee = _getFee(fftAmount);
        uint256 targetAmount = fftAmount + fee;
        uint256 allowance = _fft.allowance(msg.sender, address(this));

        while (targetAmount > allowance) {
            nftAmount -= 1e18;
            fftAmount = _mul(nftAmount, _price);
            fee = _getFee(fftAmount);
            targetAmount = fftAmount + fee;
        }

        if (targetAmount == 0) {
            revert InsufficientSwapAmount();
        }
    }

    function _getFee(uint256 amount) private pure returns (uint256) {
        uint256 fee = _mul(amount, 5e18);
        return _div(fee, 10000e18);
    }

    // function _deductFee(uint256 amount) private returns (uint256) {
    //     uint256 nFee = _mul(amount, 5e18);
    //     nFee = _div(nFee, 10000e18);

    //     uint256 nCollectorFee = _div(nFee, 5e18);

    //     uint256 nRemFee = nFee - nCollectorFee;

    //     uint256 collectorFee = _denormalize(nCollectorFee, decimals);
    //     uint256 remFee = _denormalize(nRemFee, decimals);

    //     _liq.withdrawFFT(collectorFee, _collector);
    //     _liq.withdrawFFT(remFee, address(this));

    //     _fees += nRemFee;

    //     return nFee;
    // }

    function _deductFee(uint256 amount) private {
        uint256 nCollectorFee = _div(amount, 5e18);

        uint256 collectorFee = _denormalize(nCollectorFee, decimals);
        uint256 remFee = amount - collectorFee;

        _liq.withdrawFFT(collectorFee, _collector);
        _liq.withdrawFFT(remFee, address(this));
        _fees += remFee;

        emit Fee(amount);
    }

    function _getPrice() private returns (uint256) {
        if (_price == 0) {
            return updatePrice();
        }

        return _price;
    }

    function swapNFT(uint256 amount) external {
        uint256 price = _price;
        (uint256 nftAmount, uint256 fftAmount, uint256 fee) = _determineCost(
            amount,
            0
        );

        _deposit(_scaleDown(nftAmount), true);
        _deductFee(fee);

        bool success;
        uint256 index;

        while (fftAmount >= price) {
            (success, index) = _findSuitableLiquid(true, price);

            if (success) {
                fftAmount = _swapNFTLiquid(index, fftAmount, price);
            } else if (fftAmount > price) {
                revert InsufficientLiquidity();
            }
        }

        updatePrice();
    }

    function swapFFT(uint256 amount) external {
        uint256 price = _price;
        (uint256 nftAmount, uint256 fftAmount, uint256 fee) = _determineCost(
            0,
            amount
        );

        _deposit(_normalize(fftAmount, decimals), false);
        _deductFee(fee);

        bool success;
        uint256 index;

        while (nftAmount >= 1e18) {
            (success, index) = _findSuitableLiquid(false, 1e18);

            if (success) {
                nftAmount = _swapFFTLiquid(index, nftAmount, price);
            } else if (nftAmount >= 1e18) {
                revert InsufficientLiquidity();
            }
        }

        updatePrice();
    }

    function _swapNFTLiquid(
        uint256 nSource,
        uint256 amount,
        uint256 price
    ) private returns (uint256) {
        uint256 altAmount;

        Liquid storage source = _liquids[nSource];
        uint256 swapAmount = source.fftAlloc <= amount
            ? source.fftAlloc
            : amount;

        altAmount = _scaleUp(_scaleDown(_div(swapAmount, price)));

        amount -= swapAmount;
        source.nftAlloc += altAmount;
        source.fftAlloc -= swapAmount;

        _liq.withdrawFFT(swapAmount, msg.sender);
        emit Swap(altAmount, swapAmount, msg.sender);

        return amount;
    }

    function _swapFFTLiquid(
        uint256 nSource,
        uint256 amount,
        uint256 price
    ) private returns (uint256) {
        Liquid storage source = _liquids[nSource];

        uint256 swapAmount = source.nftAlloc <= amount
            ? source.nftAlloc
            : amount;
        uint256 altAmount = _mul(swapAmount, price);

        amount -= swapAmount;
        source.fftAlloc += altAmount;
        source.nftAlloc -= swapAmount;

        _liq.withdrawNFT(_scaleDown(swapAmount), msg.sender);
        emit Swap(swapAmount, altAmount, msg.sender);

        return amount;
    }

    function _findSuitableLiquid(
        bool isNFT,
        uint256 minAlloc
    ) private view returns (bool success, uint256 index) {
        Liquid memory liquid;

        uint256 j;
        uint256 alloc;

        for (j = _liquids.length; j > 0 && !success; j--) {
            index = j - 1;

            liquid = _liquids[index];
            alloc = isNFT ? liquid.fftAlloc : liquid.nftAlloc;

            if (alloc >= minAlloc) {
                success = true;
            }
        }
    }
}
