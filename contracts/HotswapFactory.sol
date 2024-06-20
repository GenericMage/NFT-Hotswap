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
import "./HotswapBase.sol";
import "./HotswapController.sol";
import "./HotswapLiquidity.sol";

contract HotswapFactory is HotswapBase {
    address[] public controllers;
    address[] public liquids;

    address payable _defaultCollector;
    uint256 public constant DEPLOY_FEE = 1e15;

    constructor() {
        _defaultCollector = payable(msg.sender);
    }

    function setCollector(
        address controllerAddr,
        address addr
    ) external onlyOwner {
        HotswapController(controllerAddr).setCollector(addr);
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
        HotswapLiquidity(liquidityAddr).setController(addr);
    }

    function deployHotswap(address nft, address fft) external payable {
        require(msg.value == DEPLOY_FEE, "Invalid fee amount");

        if (_defaultCollector != address(0)) {
            _transferNative(_defaultCollector, msg.value);
        }

        HotswapController controller = new HotswapController(nft, fft);
        HotswapLiquidity liquidity = new HotswapLiquidity(nft, fft);

        address controllerAddr = address(controller);
        address liquidityAddr = address(liquidity);

        liquidity.setController(controllerAddr);
        controller.setLiquidity(liquidityAddr);

        if (_defaultCollector != address(0)) {
            controller.setCollector(_defaultCollector);
        }

        controllers.push(controllerAddr);
        liquids.push(liquidityAddr);

        emit HotswapDeployed(controllerAddr, liquidityAddr);
    }

    function setDefaultCollector(address addr) external {
        _defaultCollector = payable(addr);
    }

    event HotswapDeployed(address controller, address liquidity);
}
