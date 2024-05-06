// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./Ownable.sol";
import "./interfaces/ERC20.sol";
import "./interfaces/ERC721.sol";
import "./HotswapBase.sol";
import "./HotswapController.sol";

contract HotswapFactory is HotswapBase {
    address[] controllers;
    address[] liquidities;

    address payable _defaultCollector;

    function setCollector(
        address controllerAddr,
        address addr
    ) external onlyOwner {
        IHotswapController(controllerAddr).setCollector(addr);
    }

    function setFactory(
        address controllerAddr,
        address factoryAddr
    ) external onlyOwner {
        IOwnable(controllerAddr).transferOwnership(factoryAddr);
        address targetAddr;

        // Remove the controller from our records
        for (uint256 i = controllers.length; i > 0; i--) {
            targetAddr = controllers[i - 1];

            if (controllerAddr != targetAddr) {
                break;
            }

            uint256 last = controllers.length - 1;
            if (i != last) {
                controllers[i] = controllers[last];
            }

            controllers.pop();
        }
    }

    function setController(
        address liquidityAddr,
        address addr
    ) external onlyOwner {
        IHotswapLiquidity(liquidityAddr).setController(addr);
    }

    function deployHotswap(address nft, address fft) external payable {
        require(msg.value == 1e18, "Invalid fee amount");

        // TODO: Probably allow default collector to be changable
        if (_defaultCollector != address(0)) {
            _transferNative(_defaultCollector, msg.value);
        }

        HotswapController controller = new HotswapController(nft, fft);
        HotswapLiquidity liquidity = new HotswapLiquidity(nft, fft);

        address controllerAddr = address(controller);
        address liquidityAddr = address(liquidity);

        liquidity.setController(controllerAddr);
        controller.setLiquidity(liquidityAddr);

        controllers.push(controllerAddr);
        liquidities.push(address(liquidity));
    }

    function setDefaultCollector(address addr) external {
        _defaultCollector = payable(addr);
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
}
