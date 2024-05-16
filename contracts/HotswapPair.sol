// SPDX-License-Identifier: BSD-3-Clause
// Sources:
// https://github.com/UniLend/unilendv2/blob/main/contracts/position.sol
pragma solidity ^0.8.25;

import "./HotswapBase.sol";
import "./interfaces/ERC20.sol";
import "./interfaces/ERC721.sol";

contract HotswapPair is HotswapBase, IERC721Receiver {
    address public NFT;
    address public FFT;

    ERC20 internal _fft;
    ERC721Enumerable internal _nft;
    uint8 public decimals = 18;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    function name() external view returns (string memory) {
        if (NFT == address(0) && FFT == address(0)) {
            return "Legacy";
        }

        string memory nftName = _nft.name();
        string memory fftName = _fft.name();

        string memory buffer = string.concat(nftName, " - ");

        return string.concat(buffer, fftName);
    }

    function setNFT(address addr) private {
        NFT = addr;
        _nft = ERC721Enumerable(addr);
    }

    function setFFT(address addr) private {
        FFT = addr;
        _fft = ERC20(addr);

        try _fft.decimals() returns (uint8 dec) {
            decimals = dec;
        } catch {}
    }

    constructor(address nft, address fft) {
        setNFT(nft);
        setFFT(fft);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return _ERC721_RECEIVED;
    }
}
