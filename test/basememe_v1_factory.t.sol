//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Test.sol";
import '../src/basememe_v1_factory.sol';

contract factory_test is Test {
    basememe_v1_factory factory;

    function setUp() public {
        factory = new basememe_v1_factory("Basememe test token", "BMTT", 1000, 900, 100);
    }

    function testCreator() public view {
        assertEq(factory.getCreator(), address(this));
    }
}