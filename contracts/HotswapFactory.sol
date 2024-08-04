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

struct AddressPair {
    address controller;
    address liquidity;
}

contract HotswapFactory is Ownable {
    mapping(uint256 => AddressPair) public pairs;
    mapping(address => mapping(address => uint256)) private indexMap;
    uint256 _pairLength;

    address payable _defaultCollector;
    uint256 public constant DEPLOY_FEE = 1e15;
    uint256 private constant DEV = 9466;

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
        HotswapController ctrl = HotswapController(controllerAddr);
        address liquidityAddr = ctrl._liquidity();

        HotswapLiquidity liq = HotswapLiquidity(liquidityAddr);

        ctrl.transferOwnership(factoryAddr);
        try liq.transferOwnership(factoryAddr) {} catch {}

        _removePair(controllerAddr, liquidityAddr);

        try
            HotswapFactory(factoryAddr).adoptController(controllerAddr)
        {} catch {}
    }

    function adoptController(address controller) external {
        HotswapController ctrl = HotswapController(controller);

        if (ctrl.owner() != address(this)) {
            revert ControllerNotOwned();
        }

        address liquidity = ctrl._liquidity();

        (bool valid, ) = _getPair(controller, liquidity);

        if (valid) {
            revert DuplicatePair();
        }

        _addPair(controller, liquidity);
    }

    function _addPair(address controller, address liquidity) private {
        indexMap[controller][liquidity] = _pairLength;
        pairs[_pairLength++] = AddressPair(controller, liquidity);
    }

    function setLiquidity(
        address controllerAddr,
        address newAddr
    ) external onlyOwner {
        HotswapController ctrl = HotswapController(controllerAddr);
        HotswapLiquidity liq = HotswapLiquidity(newAddr);
        address liquidityAddr = ctrl._liquidity();

        _removePair(controllerAddr, liquidityAddr);

        ctrl.setLiquidity(newAddr);
        try liq.setController(controllerAddr) {} catch {}

        _addPair(controllerAddr, newAddr);
    }

    function setController(
        address liquidityAddr,
        address newAddr
    ) external onlyOwner {
        HotswapController ctrl = HotswapController(newAddr);
        HotswapLiquidity liq = HotswapLiquidity(liquidityAddr);
        address controllerAddr = liq.controller();

        _removePair(controllerAddr, liquidityAddr);

        liq.setController(newAddr);
        try ctrl.setLiquidity(liquidityAddr) {} catch {}

        _addPair(newAddr, liquidityAddr);
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

        _addPair(controllerAddr, liquidityAddr);

        emit HotswapDeployed(controllerAddr, liquidityAddr);
    }

    function _getPair(
        address controller,
        address liquidity
    ) private view returns (bool valid, uint256 n) {
        n = indexMap[controller][liquidity];
        AddressPair memory pair = pairs[n];
        valid = pair.controller == controller && pair.liquidity == liquidity;
    }

    function _removePair(address controller, address liquidity) private {
        if (_pairLength == 0) {
            return;
        }

        (bool valid, uint256 n) = _getPair(controller, liquidity);

        if (!valid) {
            return;
        }

        uint256 nlast = _pairLength > 0 ? _pairLength - 1 : 0;
        AddressPair memory last = pairs[nlast];

        delete pairs[nlast];
        delete indexMap[controller][liquidity];

        if (nlast != n) {
            indexMap[last.controller][last.liquidity] = n;
            pairs[n] = last;
        }

        _pairLength--;
    }

    function setDefaultCollector(address addr) external {
        _defaultCollector = payable(addr);
    }

    function _transferNative(
        address payable to,
        uint256 amount
    ) private returns (bool) {
        if (to.send(amount)) {
            emit NativeTransferred(amount, to);
            return true;
        }

        return false;
    }

    event NativeTransferred(uint256 amount, address targetAddr);
    event HotswapDeployed(address controller, address liquidity);

    error ControllerNotOwned();
    error DuplicatePair();
}
