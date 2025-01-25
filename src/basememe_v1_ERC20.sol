//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./basememe_v1_factory.sol";
import "./basememe_v1_coinpool.sol";

/**
*    @title basememe_v1_ERC20
*
*    Implement the EIP20 but for our memecoins.
*
*    We didn't use the ERC20 contract from OpenZeppelin
*    because it just break my mind to use it (spaghetti code).
*    So we wrote our own implementation.
*
*    This contract must be deployed with the v1 factory contract.
*/
contract basememe_v1_ERC20 {
    using SafeMath for uint256;

    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _maxSupply;

    string private _name;
    string private _symbol;

    address private factory;

    pool private _coinPool;

    /**
    *    Constructor need:
    *    - name
    *    - symbol
    *    - maxSupply
    *    - coinPool address
    *    - coinPool amount (minimum 40%)
    *    - creator address
    *    - creator amount (maximum 3%)
    *
    *    It will mint all the supply and send 
    *    to the creator and the coinPool the 
    *    defined amounts.
     */
    constructor(string memory name_, string memory symbol_, uint256 maxSupply_, address coinPool_, uint256 coinPoolAmount_, address creator_, uint256 creatorAmount_) {
        factory = msg.sender;

        _name = name_;
        _symbol = symbol_;
        _maxSupply = maxSupply_;

        _coinPool = pool(coinPool_);
        mint(address(this), coinPoolAmount_);
        _coinPool.giveCoin(coinPoolAmount_);

        mint(creator_, creatorAmount_);
    }

    // EIP20 standard functions

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    // 18 like ETH
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view virtual returns (uint256) {
        return _balances[_owner];
    }

    function transfer(address _to, uint256 _value) public virtual returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _to, uint256 _value) public virtual returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(allowance(_from, _to) > _value, "basememe v1 ERC20: transferFrom value exceeds allowance");
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool){
        require(_spender != address(0), "basememe v1 ERC20: approve to the zero address");
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return _allowances[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // Usefull to avoid to rewrite the same code for transfer and transferFrom
    function _transfer(address from, address to, uint256 value) internal virtual {
        require(from != address(0), "basememe v1 ERC20: transfer from the zero address");
        require(to != address(0), "basememe v1 ERC20: transfer to the zero address");
        require(_balances[from] >= value, "basememe v1 ERC20: transfer value exceeds balance");

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);

        emit Transfer(from, to, value);
    }

    // Start of our functions outside of the EIP20 standard

    // Mint function is reserved to the factory and the contract itself
    function mint(address to, uint256 amount) internal virtual {
        require(msg.sender == factory || msg.sender == address(this), "basememe v1 ERC20: FORBIDDEN");
        require(to != address(0), "basememe v1 ERC20: mint to the zero address");
        require(amount > 0, "basememe v1 ERC20: mint amount must be greater than 0");

        require(_totalSupply.add(amount) < _maxSupply, "basememe v1 ERC20: mint amount exceeds max supply");
        _totalSupply = _totalSupply.add(amount);

        emit Mint(to, amount);
    }

    // Everyone can burn tokens
    function burn(uint256 amount) public virtual {
        require(_balances[msg.sender] > amount, "basememe v1 ERC20: burn amount exceeds balance");

        _totalSupply = _totalSupply.sub(amount);

        _transfer(msg.sender, address(0), amount);

        emit Transfer(msg.sender, address(0), amount);
    }

    event Mint(address indexed to, uint256 amount); // To easily track the minting process
}

// SafeMath from OpenZeppelin
library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}