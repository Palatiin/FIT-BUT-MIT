//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";

contract TokenTest is Test {
    Token public token;
    address[] public addresses;

    /**
     * 5 addresses, first 2 are minting admins.
     */
    function initToken(uint256 _maxSupply, uint256 _maxDailyMint) public {
        delete addresses;

        for (uint i = 1; i < 5; i++) {
            addresses.push(vm.addr(i));
        }

        address[] memory mintingAdmins = new address[](2);
        mintingAdmins[0] = addresses[0];
        mintingAdmins[1] = addresses[1];

        token = new Token(_maxSupply, mintingAdmins, _maxDailyMint);
    }

    function test_mint_admin() public {
        initToken(1000, 100);
        assertEq(token.totalSupply(), 0, "Total supply should be 0");

        // Test minting 10 tokens
        vm.prank(addresses[0]);
        token.mint(addresses[2], 10);
        assertEq(token.totalSupply(), 10, "Total supply should be 10");
        assertEq(token.balanceOf(addresses[2]), 10, "Balance of 2 should be 10");

        // Test non-admin cannot mint
        vm.expectRevert("Not a minting admin");
        vm.prank(addresses[2]);
        token.mint(addresses[3], 10);
    }

    function test_mint_over_total_supply() public {
        initToken(100, 200);
        assertEq(token.totalSupply(), 0, "Total supply should be 0");

        vm.expectRevert("Max supply exceeded");
        vm.prank(addresses[0]);
        token.mint(addresses[2], 110);
    }

    function test_mint_daily_limit() public {
        initToken(1000, 100);
        assertEq(token.totalSupply(), 0, "Total supply should be 0");

        // Test minting 100 tokens
        vm.prank(addresses[0]);
        token.mint(addresses[2], 100);
        assertEq(token.totalSupply(), 100, "Total supply should be 100");
        assertEq(token.balanceOf(addresses[2]), 100, "Balance of 2 should be 100");

        // Test daily mint limit
        vm.expectRevert("Max daily mint exceeded");
        vm.prank(addresses[0]);
        token.mint(addresses[2], 100);

        // Test daily mint limit reset
        vm.warp(block.timestamp + 1 days);
        vm.prank(addresses[0]);
        token.mint(addresses[2], 100);
        assertEq(token.totalSupply(), 200, "Total supply should be 200");
        assertEq(token.balanceOf(addresses[2]), 200, "Balance of 2 should be 200");
    }
}
