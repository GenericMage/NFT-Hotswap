// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Ownable.sol";
import "./interfaces/ERC721.sol";
import "./libraries/SafeMath.sol";

contract HotswapControllerBase is Ownable {
    using SafeMath for uint256;

    address public collector;
    mapping(uint => Liquid) public xLiquid;
    mapping(uint => Liquid) public yLiquid;

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
        bool claimed;
        uint256 index;
        ERC721 inst;
    }
}
