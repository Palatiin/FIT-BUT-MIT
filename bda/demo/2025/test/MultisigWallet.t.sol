// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {MultisigWallet} from "../src/MultisigWallet.sol";

contract MultisigWalletTest is Test {
    MultisigWallet public wallet;
    address[] public owners;

    function initWallet(uint signersCount, uint ownerCount) public {
        delete owners;

        for (uint i = 1; i <= ownerCount; i++)  {
            owners.push(vm.addr(i));
        }

        wallet = new MultisigWallet(owners, signersCount);
    }

    function test_initialZeroBalance() public {
        initWallet(2, 2);

        uint256 balance = address(wallet).balance;

        assertEq(balance, 0, "Wallet should have zero balance initially");
    }

    function test_owners() public {
        initWallet(2, 2);

        address[] memory receivedOwners = wallet.getOwners();

        assertEq(receivedOwners[0], owners[0], "First wallet owner should match constructor");
        assertEq(receivedOwners[1], owners[1], "Second wallet owner should match constructor");
    }

    function test_receive() public {
        initWallet(2, 2);

        vm.expectEmit();
        emit MultisigWallet.Deposit(vm.addr(3), 1 ether);

        StdCheats.hoax(vm.addr(3), 100 ether);
        (bool success, ) = address(wallet).call{value: 1 ether}("");
        assertTrue(success);

        uint256 walletBalance = address(wallet).balance;
        assertEq(walletBalance, 1 ether, "Wallet should have balance of 1 ETH");

        uint256 senderBalance = vm.addr(3).balance;
        assertEq(senderBalance, 99 ether, "Sender should have balance of 99 ETH");
    }

    function test_submitTransaction() public {
        initWallet(2, 2);

        assertEq(wallet.transactionCount(), 0, "Transaction count should be 0 initially");

        // charge contract
        StdCheats.hoax(vm.addr(1), 1 ether);
        (bool success, ) = address(wallet).call{value: 1 ether}("");
        assertTrue(success);

        // check if non-owner is denied from creating transactions
        vm.expectRevert("Owner does not exist.");
        vm.prank(vm.addr(3));
        wallet.submitTransaction(vm.addr(3), 0.5 ether);

        // check events emitted Submission and Confirmation
        vm.expectEmit();
        emit MultisigWallet.Submission(0);

        vm.expectEmit();
        emit MultisigWallet.Confirmation(vm.addr(1), 0);

        // submit tx (suggestion)
        vm.prank(vm.addr(1));
        wallet.submitTransaction(vm.addr(3), 0.5 ether);

        // tx count should be 1
        assertEq(wallet.transactionCount(), 1, "Transaction count should be 0 initially");

        // signature count should be 1
        assertEq(wallet.getSignatureCount(0), 1, "Transaction signature count should be 1");

        // tx is not confimed
        assertFalse(wallet.isTransactionConfirmed(0), "Transaction should not yet be confirmed");

        // execution should fail
        vm.expectRevert("Transaction is not yet confirmed.");
        wallet.executeTransaction(0);

        // check if receiver didn't receive any funds
        uint256 receiverBalance = vm.addr(3).balance;
        uint256 contractBalance = address(wallet).balance;
        assertEq(receiverBalance, 0 ether, "Receiver should have balance of 0 ETH");
        assertEq(contractBalance, 1 ether, "Contract should have balance of 1 ETH");
    }

    function test_confirmTransaction() public {
        initWallet(2, 2);

        // charge contract
        StdCheats.hoax(vm.addr(1), 1 ether);
        (bool success, ) = address(wallet).call{value: 1 ether}("");
        assertTrue(success);

        // submit tx (suggestion)
        vm.prank(vm.addr(1));
        wallet.submitTransaction(vm.addr(3), 0.5 ether);

        // check event emitted Confirmation
        vm.expectEmit();
        emit MultisigWallet.Confirmation(vm.addr(2), 0);

        // sign tx
        vm.prank(vm.addr(2));
        wallet.confirmTransaction(0);

        bool isConfirmed = wallet.isTransactionConfirmed(0);
        assertTrue(isConfirmed, "Transaction should be confirmed.");

        // execution should pass
        wallet.executeTransaction(0);

        // check if receiver received funds
        uint256 receiverBalance = vm.addr(3).balance;
        assertEq(receiverBalance, 0.5 ether, "Receiver should have balance of 0.5 ETH");

        // check if contract balance updated
        uint256 contractBalance = address(wallet).balance;
        assertEq(contractBalance, 0.5 ether, "Contract should have balance of 0.5 ETH");
    }

    function test_replayProtection() public {
        initWallet(2, 2);

        // charge contract
        StdCheats.hoax(vm.addr(1), 1 ether);
        (bool success, ) = address(wallet).call{value: 1 ether}("");
        assertTrue(success);

        // submit tx (suggestion)
        vm.prank(vm.addr(1));
        wallet.submitTransaction(vm.addr(3), 0.5 ether);

        // sign tx
        vm.prank(vm.addr(2));
        wallet.confirmTransaction(0);

        // execute
        wallet.executeTransaction(0);

        // check if second execution fails
        vm.expectRevert();
        wallet.executeTransaction(0);

        // check if receiver received funds
        uint256 receiverBalance = vm.addr(3).balance;
        assertEq(receiverBalance, 0.5 ether, "Receiver should have balance of 0.5 ETH");

        // check if contract balance updated
        uint256 contractBalance = address(wallet).balance;
        assertEq(contractBalance, 0.5 ether, "Contract should have balance of 0.5 ETH");
    }

    function test_notEnoughBalanceEmit() public {
        initWallet(2, 2);

        // submit tx (suggestion)
        vm.prank(vm.addr(1));
        wallet.submitTransaction(vm.addr(3), 0.5 ether);

        // check event emitted Confirmation
        vm.expectEmit();
        emit MultisigWallet.Confirmation(vm.addr(2), 0);

        // sign tx
        vm.prank(vm.addr(2));
        wallet.confirmTransaction(0);

        bool isConfirmed = wallet.isTransactionConfirmed(0);
        assertTrue(isConfirmed, "Transaction should be confirmed.");

        vm.expectEmit();
        emit MultisigWallet.NotEnoughBalance(0 ether, 0.5 ether);
        wallet.executeTransaction(0);
    }

    function test_multisig() public {
        // check if fail when req. signatures is 0 or 1
        vm.expectRevert();
        initWallet(0, 2);

        vm.expectRevert();
        initWallet(1, 2);

        // ======================================================================
        // check if fail when req. signatures > number of owners
        vm.expectRevert();
        initWallet(1, 0);

        vm.expectRevert();
        initWallet(5, 4);

        // ======================================================================
        // create 3 of 3 multisig
        initWallet(3, 3);

        bool isConfirmed;
        bool success;
        uint256 receiverBalance;
        uint256 contractBalance;

        // charge contract
        StdCheats.hoax(vm.addr(1), 1 ether);
        (success, ) = address(wallet).call{value: 1 ether}("");
        assertTrue(success);

        // submit tx (suggestion)
        vm.prank(vm.addr(1));
        wallet.submitTransaction(vm.addr(3), 0.5 ether);

        // check event emitted Confirmation
        vm.expectEmit();
        emit MultisigWallet.Confirmation(vm.addr(2), 0);

        // 2nd signature
        vm.prank(vm.addr(2));
        wallet.confirmTransaction(0);

        isConfirmed = wallet.isTransactionConfirmed(0);
        assertFalse(isConfirmed, "Transaction should not be confirmed.");

        // 3rd signature
        vm.prank(vm.addr(3));
        wallet.confirmTransaction(0);

        isConfirmed = wallet.isTransactionConfirmed(0);
        assertTrue(isConfirmed, "Transaction should be confirmed.");

        // execution should pass
        wallet.executeTransaction(0);

        // check if receiver received funds
        receiverBalance = vm.addr(3).balance;
        assertEq(receiverBalance, 0.5 ether, "Receiver should have balance of 0.5 ETH");

        // check if contract balance updated
        contractBalance = address(wallet).balance;
        assertEq(contractBalance, 0.5 ether, "Contract should have balance of 0.5 ETH");

        vm.deal(vm.addr(3), 0);

        // ======================================================================
        // create 4 of 5 multisig

        initWallet(4, 5);

        // charge contract
        StdCheats.hoax(vm.addr(1), 1 ether);
        (success, ) = address(wallet).call{value: 1 ether}("");
        assertTrue(success);

        // submit tx (suggestion)
        vm.prank(vm.addr(1));
        wallet.submitTransaction(vm.addr(3), 0.5 ether);

        // check event emitted Confirmation
        vm.expectEmit();
        emit MultisigWallet.Confirmation(vm.addr(2), 0);

        // 2nd signature
        vm.prank(vm.addr(2));
        wallet.confirmTransaction(0);

        // 3rd signature
        vm.prank(vm.addr(3));
        wallet.confirmTransaction(0);

        isConfirmed = wallet.isTransactionConfirmed(0);
        assertFalse(isConfirmed, "Transaction should not be confirmed.");

        // 4th signature
        vm.prank(vm.addr(4));
        wallet.confirmTransaction(0);

        isConfirmed = wallet.isTransactionConfirmed(0);
        assertTrue(isConfirmed, "Transaction should be confirmed.");

        // execution should pass
        wallet.executeTransaction(0);

        // check if receiver received funds
        receiverBalance = vm.addr(3).balance;
        assertEq(receiverBalance, 0.5 ether, "Receiver should have balance of 0.5 ETH");

        // check if contract balance updated
        contractBalance = address(wallet).balance;
        assertEq(contractBalance, 0.5 ether, "Contract should have balance of 0.5 ETH");
    }

    function test_getOwnersWhoSignedTx() public {
        initWallet(2, 3);

        // charge contract
        StdCheats.hoax(vm.addr(1), 1 ether);
        (bool success, ) = address(wallet).call{value: 1 ether}("");
        assertTrue(success);

        // submit tx (suggestion)
        vm.prank(vm.addr(1));
        wallet.submitTransaction(vm.addr(3), 0.5 ether);

        address[] memory signers = wallet.getOwnersWhoSignedTx(0);
        address[] memory expected = new address[](1);
        expected[0] = vm.addr(1);

        assertEq(signers, expected, "Function should return 1 signer");

        vm.prank(vm.addr(2));
        wallet.confirmTransaction(0);

        signers = wallet.getOwnersWhoSignedTx(0);
        expected = new address[](2);
        expected[0] = vm.addr(1);
        expected[1] = vm.addr(2);

        assertEq(signers, expected, "Function should return 2 signers");

        vm.prank(vm.addr(3));
        wallet.confirmTransaction(0);

        signers = wallet.getOwnersWhoSignedTx(0);
        expected = new address[](3);
        expected[0] = vm.addr(1);
        expected[1] = vm.addr(2);
        expected[2] = vm.addr(3);

        assertEq(signers, expected, "Function should return 3 signers");
    }
}
