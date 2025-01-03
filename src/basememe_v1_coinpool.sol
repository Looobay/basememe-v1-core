//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./basememe_v1_ERC20.sol";

interface pool {
    function giveCoin(uint256 amount) external;
}

contract basememe_v1_coinpool is pool {
    using SafeMath for uint256;

    basememe_v1_ERC20 private erc20;

    uint256 private totalCoins_;
    uint256 private totalWei_;
    uint256 private priceCoin_; // price in Wei

    uint256 private demand;
    uint256 private supply;

    constructor(address erc20_) {
        erc20 = basememe_v1_ERC20(erc20_);

        priceCoin_ = 10000000000; // 1 Coin per 10000000000 Wei (0,00000001 ETH) for the first price
    }

    // To fund the coinpool from the ERC20 contract
    function giveCoin(uint256 amount) external {
        require(erc20.approve(address(this), amount), "basememe v1 coinpool: approve failed");
        require(erc20.transferFrom(msg.sender, address(this), amount), "basememe v1 coinpool: transferFrom failed");

        totalCoins_.add(amount);

        emit coinGiven(msg.sender, amount);
    }

    // pay ETH and get coins
    function buyCoin() public payable {
        require(msg.value > 0, "basememe v1 coinpool: ETH amount must be greater than 0");

        uint256 weiValue = msg.value;
        uint256 coinToBuy = weiValue.mul(priceCoin_);

        require(coinToBuy < totalCoins_, "basememe v1 coinpool: not enough coins in the pool, check the pool balance");

        erc20.transfer(msg.sender, coinToBuy);
        totalWei_ = totalWei_.add(weiValue);
        totalCoins_.sub(coinToBuy);

        demand = demand.add(coinToBuy);

        if(supply.sub(coinToBuy) >= 0) {
            supply = supply.sub(coinToBuy);
        } else {
            supply = supply; // We can't have a negative supply
        }

        updatePrice();
        emit coinBought(msg.sender, coinToBuy);
    }

    // pay coins and get ETH
    function sellCoin(uint256 amount) public {
        require(amount > 0, "basememe V1 coinpool: You need to spend coins to sell coins");

        uint256 weiToRecover = amount.div(priceCoin_);

        uint256 allowance = erc20.allowance(msg.sender, address(this));
        require(allowance >= amount, "basememe V1 coinpool: Your allowance is not well defined");

        erc20.transferFrom(msg.sender, address(this), amount);
        totalCoins_ = totalCoins_.add(amount);

        payable(msg.sender).transfer(weiToRecover);
        totalWei_ = totalWei_.sub(weiToRecover);

        supply = supply.add(amount);

        if(demand.sub(amount) >= 0) {
            demand = demand.sub(amount);
        } else {
            demand = demand; // We can't have a negative demand
        }

        updatePrice();
        emit coinSold(msg.sender, amount);
    }

    function updatePrice() internal {
        if (demand > supply) {
            priceCoin_ = priceCoin_.add((priceCoin_.mul((demand.sub(supply)))).div(supply.add(1))); // more expansive
        } else if (supply > demand) {
            priceCoin_ = priceCoin_.sub((priceCoin_.mul((supply.sub(demand)))).div(supply.add(1))); // less expansive
        }
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
}