// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC721.sol";
import "./HotswapBase.sol";
import "./HotswapController.sol";

contract HotswapFactory is HotswapBase {
    address[] controllers;
    address[] liquidity;

    address _defaultCollector;


    function setCollector(address controllerAddr, address addr) external onlyOwner {
        IHotswapController(controllerAddr).setCollector(addr);
    }

    function setFactory(address controllerAddr, address factoryAddr) external onlyOwner {
        IHotswapController(controllerAddr).transferOwnership(factoryAddr);
        delete _controllers[controllerAddr];
    }

    function setController(address liquidityAddr, address addr) external onlyOwner {
        IHotswapLiquidity(liquidity).setController(addr);
    }

    function deployHotswap(address nft, address fft) external {
        require(msg.value == 1e18, "Invalid fee amount");

        if (_collector != address(0)) {
            _transferNative(_collector, msg.value)
        }
        
        HotswapController controller = HotswapController(nft, fft);
        address controllerAddr = address(controller);

        HotswapLiquidity liquidity = HotswapLiquidity(nft, fft);
        liquidity.setController(controllerAddr);
        
        controllers.push(controllerAddr);
        liquidity.push(address(liquidity));
    }

    function setDefaultCollector(address addr) external {
        _defaultCollector = addr;
    }
}
