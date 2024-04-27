// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Ownable.sol";
import "./interfaces/ERC721.sol";
import "./libraries/SafeMath.sol";
import "./HotswapLiquidity.sol";

interface IHotswapController {
    function setCollector(address addr) external;
}

interface IHotswapLiquidity {
    function setController(address addr) external;
}

contract HotswapControllerBase is Ownable, IHotswapController {
    using SafeMath for uint256;

    address public collector;

    mapping(address => uint256[]) internal _liquidityByUser;
    Liquid[] liquidities;

    function setCollector(address addr) external {
        collector = addr;
    }

    struct Liquid {
        address depositor;
        uint256 depositedAt;
        bool depositType;
        uint256 price;
        uint256 xAlloc;
        uint256 yAlloc;
        uint256 fees;
        bool claimed;
        uint256 userIndex;
    }
}
