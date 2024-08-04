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
    constructor(address nft, address fft) HotswapControllerBase(nft, fft) {}

    function fees() public view returns (uint256) {
        return _liq.fees();
    }

    function tVolume() public view returns (uint256) {
        return _liq.tVolume();
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
        uint256 balance = isNFT
            ? _nft.balanceOf(msg.sender)
            : _fft.balanceOf(msg.sender);

        if (amount > balance || amount == 0) {
            revert InsufficientBalance(amount, balance);
        }

        if (isNFT) {
            uint256 tokenId;
            bytes memory data = new bytes(0);

            for (uint256 i = 0; i < amount; i++) {
                tokenId = _nft.tokenOfOwnerByIndex(msg.sender, 0);
                _nft.safeTransferFrom(msg.sender, _liquidity, tokenId, data);
            }
        } else if (!_fft.transferFrom(msg.sender, _liquidity, amount)) {
            revert DepositFailed();
        }
    }

    function _createLiquid(uint256 amount, bool isNFT) private {
        nuint256 allocRatio;

        if (isNFT) {
            amount = _scaleUp(amount);
            allocRatio = _div(amount, _fetchLiquidity(isNFT));
        } else {
            allocRatio = _div(amount, _fetchLiquidity(isNFT));
        }

        _liq.createLiquid(msg.sender, amount, allocRatio, isNFT);
        _updatePrice();
    }

    function queryLiquid(
        uint256 index,
        bool isNFT
    )
        external
        view
        returns (
            uint256 alloc,
            nuint256 allocRatio,
            uint256 dVolume,
            bool claimed
        )
    {
        return _liq.queryLiquid(msg.sender, index, isNFT);
    }

    function queryLiquidbyDepositor(
        address depositor,
        uint256 index,
        bool isNFT
    )
        external
        view
        returns (
            uint256 alloc,
            nuint256 allocRatio,
            uint256 dVolume,
            bool claimed
        )
    {
        return _liq.queryLiquid(depositor, index, isNFT);
    }

    function _fetchLiquidity(bool isNFT) private view returns (uint256) {
        if (isNFT) {
            return _scaleUp(nftLiquidity());
        }

        return fftLiquidity();
    }

    function claimFee(uint256 index, bool isNFT) public {
        address targetAddr = msg.sender;

        (, nuint256 allocRatio, uint256 dVolume, bool claimed) = _liq
            .queryLiquid(msg.sender, index, isNFT);

        if (claimed) {
            revert FeeAlreadyClaimedForSlot();
        }

        uint256 tVol = tVolume();
        uint256 cumulativeVol = tVol - dVolume;

        nuint256 volRatio = _div(cumulativeVol, tVol);
        nuint256 fees_ = _mul(volRatio, fees());
        nuint256 noutput = _mul(fees_, allocRatio);

        uint256 output = _denormalize(noutput);

        _liq.withdrawFFT(output, targetAddr);
        _liq.claimLiquid(msg.sender, index, isNFT);

        _liq.withdrawFees(output);
        emit FeeClaimed(targetAddr, output);
    }

    function withdrawLiquidity(uint256 index, bool isNFT) external {
        (uint256 alloc, nuint256 allocRatio, , ) = _liq.queryLiquid(
            msg.sender,
            index,
            isNFT
        );

        uint256 currentLiquidity = _fetchLiquidity(isNFT);

        uint256 outputAmount = _denormalize(_mul(currentLiquidity, allocRatio));

        if (outputAmount > alloc) {
            outputAmount = alloc;
        }

        _liq.removeLiquid(msg.sender, index, isNFT);

        if (isNFT) {
            outputAmount = _scaleDown(outputAmount);
            _liq.withdrawNFT(outputAmount, msg.sender);
        } else {
            _liq.withdrawFFT(outputAmount, msg.sender);
        }
    }

    function _addVolume(uint256 amount) private {
        _liq.addVolume(amount);
    }

    function _determineCost(
        bool isSell,
        uint256 nft,
        uint256 constraint,
        uint256 price
    ) private view returns (uint256 nftAmount, uint256 fftAmount, uint256 fee) {
        if (price == 0) {
            revert InvalidSwapPrice();
        }

        uint256 minout = 0;
        uint256 maxin = 0;

        uint256 threshold = _denormalize(
            _mul(fftLiquidity(), MAX_LIQUIDITY_CONSTANT)
        );

        if (isSell) {
            maxin = threshold;
            minout = constraint;
        } else {
            maxin = constraint;
            minout = 0;

            if (maxin > threshold) {
                maxin = threshold;
            }
        }

        nftAmount = _scaleUp(nft);
        fftAmount = _denormalize(_mul(nftAmount, price));

        fee = _getFee(fftAmount);
        uint256 targetAmount = fftAmount + fee;
        uint256 allowance;

        if (isSell) {
            allowance = type(uint256).max;
        } else {
            allowance = _fft.allowance(msg.sender, address(this));
        }

        while (targetAmount > allowance || targetAmount > maxin) {
            nftAmount -= _nftScalar;
            fftAmount = _denormalize(_mul(nftAmount, price));

            fee = _getFee(fftAmount);
            targetAmount = fftAmount + fee;
        }

        if (targetAmount == 0 || targetAmount < minout) {
            revert InsufficientSwapAmount();
        }
    }

    function _getFee(uint256 amount) private view returns (uint256) {
        return _denormalize(_mul(amount, FEE_CONSTANT));
    }

    function _deductFee(uint256 fee) private {
        uint256 collectorFee = _denormalize(_mul(fee, COLLECTOR_CONSTANT));
        uint256 remFee = fee - collectorFee;

        _liq.withdrawFFT(collectorFee, _collector);
        _liq.allocateFees(remFee);

        emit ChargedFee(fee);
    }

    function swapNFT(uint256 nftCount, uint256 minOutput) external {
        uint256 price = _price;
        (uint256 nftAmount, uint256 fftAmount, uint256 fee) = _determineCost(
            true,
            nftCount,
            minOutput,
            price
        );

        uint256 dnft = _scaleDown(nftAmount);
        uint256 dfft = fftAmount;

        price = _computePrice(nftLiquidity() + dnft, fftLiquidity() - dfft);

        (nftAmount, fftAmount, fee) = _determineCost(
            true,
            nftCount,
            minOutput,
            price
        );

        dnft = _scaleDown(nftAmount);
        dfft = fftAmount;

        _deposit(dnft, true);
        _deductFee(fee);

        uint256 tfft = fftLiquidity();
        if (fftAmount > tfft) {
            revert InsufficientLiquidity();
        }

        _liq.withdrawFFT(dfft, msg.sender);
        emit Swap(dnft, dfft, msg.sender, price);

        _addVolume(fftAmount);
        _updatePrice();
    }

    function swapFFT(uint256 nftCount, uint256 maxInput) external {
        uint256 price = _price;
        (uint256 nftAmount, uint256 fftAmount, uint256 fee) = _determineCost(
            false,
            nftCount,
            maxInput,
            price
        );

        uint256 dnft = _scaleDown(nftAmount);
        uint256 dfft = fftAmount;

        uint256 dtnft = nftLiquidity();
        if (dnft > dtnft) {
            revert InsufficientLiquidity();
        }

        _deposit(dfft, false);
        _deductFee(fee);

        _liq.withdrawNFT(dnft, msg.sender);
        emit Swap(dnft, dfft, msg.sender, price);

        _updatePrice();
        _addVolume(fftAmount);
    }
}
