// SPDX-License-Identifier: BSD-3-Clause
//   ::   .:      ...   :::::::::::: .::::::..::    .   .::::::.  ::::::::::.
//  ,;;   ;;,  .;;;;;;;.;;;;;;;;'''';;;`    `';;,  ;;  ;;;' ;;`;;  `;;;```.;;;
// ,[[[,,,[[[ ,[[     \[[,   [[     '[==/[[[[,'[[, [[, [[' ,[[ '[[, `]]nnn]]'
// "$$$"""$$$ $$$,     $$$   $$       '''    $  Y$c$$$c$P c$$$cc$$$c $$$""
//  888   "88o"888,_ _,88P   88,     88b    dP   "88"888   888   888,888o
//  MMM    YMM  "YMMMMMP"    MMM      "YMmMY"     "M "M"   YMM   ""` YMMMb

pragma solidity ^0.8.25;

import "./Ownable.sol";
import "./interfaces/ERC20.sol";
import "./interfaces/ERC721.sol";
import "./HotswapLiquidStorage.sol";

contract HotswapLiquidity is HotswapLiquidStorage {
    address public controller;
    uint256 public fees;

    constructor(address nft, address fft) HotswapLiquidStorage(nft, fft) {}

    function nftBalance() external view returns (uint256) {
        return _nft.balanceOf(address(this));
    }

    function fftBalance() external view returns (uint256) {
        return _fft.balanceOf(address(this));
    }

    function withdrawFFT(uint256 amount, address dest) external onlyAuthorized {
        uint256 available = _fft.balanceOf(address(this));

        if (amount == 0 || amount > available) {
            revert InsufficientLiquidity(amount, available);
        }

        require(_fft.transfer(dest, amount), "Withdrawal failed");
        emit WithdrawFFT(amount, dest);
    }

    function withdrawNFT(uint256 amount, address dest) external onlyAuthorized {
        uint256 available = _nft.balanceOf(address(this));

        if (amount == 0 || amount > available) {
            revert InsufficientLiquidity(amount, available);
        }

        uint256 tokenId;
        bytes memory data = new bytes(0);

        for (uint256 i = amount; i > 0; i--) {
            tokenId = _nft.tokenOfOwnerByIndex(address(this), i - 1);
            _nft.safeTransferFrom(address(this), dest, tokenId, data);
        }

        emit WithdrawNFT(amount, dest);
    }

    function setController(address addr) external onlyOwner {
        _auth[controller] = false;
        controller = addr;
        _auth[controller] = true;
    }

    function allocateFees(uint256 amount) external onlyAuthorized {
        fees += amount;
    }

    function withdrawFees(uint256 amount) external onlyAuthorized {
        fees -= amount;
    }

    event WithdrawNFT(uint256 amount, address addr);
    event WithdrawFFT(uint256 amount, address addr);

    error InsufficientLiquidity(uint256 value, uint256 available);
}
