//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./basememe_v1_ERC20.sol";
import "./basememe_v1_coinpool.sol";

/**
*    @title basememe_v1_factory
*
*    This contract will deploy the ERC20 and the coinpool.
*/
contract basememe_v1_factory {
    address private creator;

    constructor(string memory name, string memory symbol, uint256 maxSupply, uint256 coinPoolAmount, uint256 creatorAmount){
        creator = msg.sender;
        basememe_v1_coinpool coinpool = new basememe_v1_coinpool();
        basememe_v1_ERC20 erc20 = new basememe_v1_ERC20(name, symbol, maxSupply, address(coinpool), coinPoolAmount, creator, creatorAmount);
    }
}