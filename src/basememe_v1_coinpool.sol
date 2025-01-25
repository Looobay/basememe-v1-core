//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./basememe_v1_ERC20.sol";

interface pool {
    function giveCoin(uint256 amount) external;
}

/**
*    @title basememe_v1_coinpool
*
*    With this we can buy and sell against ETH some memecoins.
*/
contract basememe_v1_coinpool is pool {
    using SafeMath for uint256;

    basememe_v1_ERC20 private erc20;

    address private owner;

    uint256 private totalCoins_;
    uint256 private totalWei_;
    uint256 private priceCoin_; // price in Wei

    uint256 private demand;
    uint256 private supply;

    constructor(){
        owner = msg.sender;
    }

    function Construct(address erc20_) public {
        require(msg.sender == owner, "basememe v1 coinpool: FORBIDDEN");
        
        erc20 = basememe_v1_ERC20(erc20_);

        priceCoin_ = 10000; // 1 Coin per 10000 Wei (0.00000000000001 ETH) for the first price

        supply = 0;
        demand = 0;
    }

    // To fund the coinpool from the ERC20 contract
    function giveCoin(uint256 amount) external {
        require(msg.sender == address(erc20), "basememe v1 coinpool: only the ERC20 contract can give coins");
        require(erc20.approve(address(this), amount), "basememe v1 coinpool: approve failed");
        require(erc20.transferFrom(msg.sender, address(this), amount), "basememe v1 coinpool: transferFrom failed");

        totalCoins_.add(amount);

        supply = supply.add(amount);

        emit coinGiven(msg.sender, amount);
    }

    // pay ETH and get coins
    function buyCoin(uint256 amount) public payable {
        require(msg.value > 0, "basememe v1 coinpool: ETH (in wei) amount must be greater than 0");

        uint256 weiValue = msg.value;
        uint256 coinToBuy = weiValue.mul(priceCoin_);

        uint256 cost = amount.mul(priceCoin_); // cost in wei to buy x amount of coins

        require(cost == amount, "basememe v1 coinpool: You did not pay the right amount of ETH for the amount of coins you've selected"); // not sure about it

        require(coinToBuy <= totalCoins_, "basememe v1 coinpool: not enough coins in the pool, check the pool balance");

        erc20.transfer(msg.sender, coinToBuy);
        totalWei_ = totalWei_.add(weiValue);
        totalCoins_.sub(coinToBuy);

        demand = demand.add(coinToBuy);

        updatePrice();
        emit coinBought(msg.sender, coinToBuy);
    }

    // pay coins and get ETH
    function sellCoin(uint256 amount) public {
        require(amount > 0, "basememe V1 coinpool: You need to spend coins to sell coins");
        require(erc20.balanceOf(msg.sender) >= amount, "basememe V1 coinpool: You don't have enough coins to sell");

        uint256 weiToRecover = amount.div(priceCoin_);

        uint256 allowance = erc20.allowance(msg.sender, address(this));
        require(allowance >= amount, "basememe V1 coinpool: Your allowance is not well defined");

        erc20.transferFrom(msg.sender, address(this), amount);
        totalCoins_ = totalCoins_.add(amount);

        payable(msg.sender).transfer(weiToRecover);
        totalWei_ = totalWei_.sub(weiToRecover);

        supply = supply.add(amount);

        updatePrice();
        emit coinSold(msg.sender, amount);
    }

    function updatePrice() private {
        if (supply > 0) {
            priceCoin_ = (totalWei_.mul(demand)).div(supply);
        }
        emit PriceUpdated(priceCoin_);
    }

    function totalCoins() public view returns (uint256) {
        return totalCoins_;
    }

    function totalWei() public view returns (uint256) {
        return totalWei_;
    }

    function totalETH() public view returns (uint256) {
        return totalWei_.div(10**18);
    }

    event coinGiven(address giver, uint256 amount);
    event coinBought(address buyer, uint256 amount);
    event coinSold(address seller, uint256 amount);
    event PriceUpdated(uint256 newPrice);
}