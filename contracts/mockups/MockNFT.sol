// SPDX-License-Identifier: BSD-3-Clause
/// @title Mock contract for ERC721 related tests
/// @dev Allows minting and checking of nft balance.
pragma solidity ^0.8.24;

contract MockNFT {
    mapping(address => uint256) wallets;

    function mint(address user) external {
        uint256 count = wallets[user];

        count++;
        wallets[user] = count;
    }

    function mintAmount(address user, uint256 amount) external {
        uint256 count = wallets[user];
        wallets[user] = count + amount;
    }

    function balanceOf(address owner) external view returns (uint256 balance) {
        return wallets[owner];
    }
}
