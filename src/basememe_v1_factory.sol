//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./basememe_v1_ERC20.sol";
import "./basememe_v1_coinpool.sol";

contract basememe_v1_factory {
    address creator;

    basememe_v1_ERC20 erc20;
    basememe_v1_coinpool coinpool;

    constructor (string memory name, string memory symbol, uint256 maxSupply, uint256 coinPoolAmount, uint256 creatorAmount) {
        creator = msg.sender;
        
        deployAll(name, symbol, maxSupply, coinPoolAmount, creatorAmount);
    }

    function deployAll(string memory name, string memory symbol, uint256 maxSupply, uint256 coinPoolAmount, uint256 creatorAmount) internal {
        coinpool = new basememe_v1_coinpool(address(new basememe_v1_ERC20(name, symbol, maxSupply, address(coinpool), coinPoolAmount, creator, creatorAmount)));
    }

    function getCreator() public view returns (address) {
        return creator;
    }
}