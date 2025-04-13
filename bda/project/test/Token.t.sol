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
            // console.log("Address", addresses[i-1]);
        }

        address[] memory mintingAdmins = new address[](2);
        mintingAdmins[0] = addresses[0];
        mintingAdmins[1] = addresses[1];

        address[] memory trustedIDPs = new address[](1);
        // Private key of the example IDP: 0x91e90072b136abfd4dec60420a22e330d5374519bda867c0406fdd650589201f
        trustedIDPs[0] = address(0x67d3D8dbD7CDddf3C70Cf93F2152a2BbF6Be7557);

        address[] memory idpAdmins = new address[](1);
        idpAdmins[0] = addresses[0];

        token = new Token(_maxSupply, mintingAdmins, _maxDailyMint, trustedIDPs, idpAdmins);
    }

    function verifyFirstThreeAddresses() public {
        vm.prank(addresses[0]);
        token.verifyIdentity(1744451468, hex"778d70ce55da76bc4a8c05e13c6c6a2a0c300acb3e9e9b19cd049feab835f7b0704d0fad4b534f28902aa504226dd0eec7643a4da3c61b3b77c2375c2a66f83a1b");

        vm.prank(addresses[1]);
        token.verifyIdentity(1744451468, hex"f4ba43a5856dd02d60fdd17a1604d0e3ed4ace742b16107d612c9652fb9520a9168df8a74215e9ca4413d52fd64e81f9a725692dd55f82a6c54096ce982e2a781b");
        
        vm.prank(addresses[2]);
        token.verifyIdentity(1744451468, hex"f748577b7f5f01ed0d840b7b56902a2b2a899608c6f8aaef7d23be633141d7ad3ac8c3df1c06d2554b673909b0bf264f5b96b5ed62ff8c4601b0b498a30199651c");
    }

    function test_verify_identity() public {
        initToken(1000, 100);

        // Verify 1. address
        vm.expectEmit();
        emit Token.IdentityVerified(addresses[0], 1744451468);
        vm.prank(addresses[0]);
        token.verifyIdentity(1744451468, hex"778d70ce55da76bc4a8c05e13c6c6a2a0c300acb3e9e9b19cd049feab835f7b0704d0fad4b534f28902aa504226dd0eec7643a4da3c61b3b77c2375c2a66f83a1b");
        console.log("Address", addresses[0], "verified");

        // Verify 2. address
        vm.expectEmit();
        emit Token.IdentityVerified(addresses[1], 1744451468);
        vm.prank(addresses[1]);
        token.verifyIdentity(1744451468, hex"f4ba43a5856dd02d60fdd17a1604d0e3ed4ace742b16107d612c9652fb9520a9168df8a74215e9ca4413d52fd64e81f9a725692dd55f82a6c54096ce982e2a781b");
        console.log("Address", addresses[1], "verified");

        // Verify 3. address
        vm.expectEmit();
        emit Token.IdentityVerified(addresses[2], 1744451468);
        vm.prank(addresses[2]);
        token.verifyIdentity(1744451468, hex"f748577b7f5f01ed0d840b7b56902a2b2a899608c6f8aaef7d23be633141d7ad3ac8c3df1c06d2554b673909b0bf264f5b96b5ed62ff8c4601b0b498a30199651c");
        console.log("Address", addresses[2], "verified");

        // Verify 3. address again
        vm.expectRevert("Identity already verified");
        vm.prank(addresses[2]);
        token.verifyIdentity(1744451468, hex"f748577b7f5f01ed0d840b7b56902a2b2a899608c6f8aaef7d23be633141d7ad3ac8c3df1c06d2554b673909b0bf264f5b96b5ed62ff8c4601b0b498a30199651c");

        
    }

    function test_add_trusted_idp() public {
        initToken(1000, 100);
        verifyFirstThreeAddresses();
        assertEq(token.totalSupply(), 0, "Total supply should be 0");

        vm.prank(addresses[0]);
        // Private key of the example IDP: 0x19cfa6079c94c889a2b68223ec9a2e4170b7c977db7319c0e2cc7f82040297eb
        token.addTrustedIDP(address(0x3f176887Ac19bbCcA11052E79BcF1533BD7CFFf9));
        assertEq(token.isTrustedIDP(address(0x3f176887Ac19bbCcA11052E79BcF1533BD7CFFf9)), true, "IDP should be trusted");

        vm.expectRevert("Not an IDP admin");
        vm.prank(addresses[1]);
        token.addTrustedIDP(address(0x3f176887Ac19bbCcA11052E79BcF1533BD7CFFf9));

        vm.prank(addresses[0]);
        token.removeTrustedIDP(address(0x3f176887Ac19bbCcA11052E79BcF1533BD7CFFf9));
        assertEq(token.isTrustedIDP(address(0x3f176887Ac19bbCcA11052E79BcF1533BD7CFFf9)), false, "IDP should not be trusted");
    }
    

    function test_mint_to_unverified_address() public {
        initToken(1000, 100);
        verifyFirstThreeAddresses();
        assertEq(token.totalSupply(), 0, "Total supply should be 0");

        vm.expectRevert("User is not verified");
        vm.prank(addresses[0]);
        token.mint(addresses[3], 10);
    }

    function test_mint_admin() public {
        initToken(1000, 100);
        verifyFirstThreeAddresses();
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
        verifyFirstThreeAddresses();
        assertEq(token.totalSupply(), 0, "Total supply should be 0");

        vm.expectRevert("Max supply exceeded");
        vm.prank(addresses[0]);
        token.mint(addresses[2], 110);
    }

    function test_mint_daily_limit() public {
        initToken(1000, 100);
        verifyFirstThreeAddresses();
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
