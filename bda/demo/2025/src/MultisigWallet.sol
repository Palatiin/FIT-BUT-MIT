// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract MultisigWallet {
    string public constant XLOGIN = "xremen01";

    event Confirmation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event NotEnoughBalance(uint256 currentBalance, uint256 requestedBalance);

    struct Transaction {
        address destination; // receiver of crypto-tokens (ETH)
        uint value; // amount to sent from the Wallet (contract)
        address sender; // sender of the transaction
        uint nonce; // number used once - to prevent replay attacks
    }

    mapping(uint => Transaction) public transactions; // mapping of transaction IDs to Transaction objects
    mapping(uint => mapping(address => bool)) public signatures; // mapping of transaction IDs to owners who already signed them
    mapping(address => bool) public isOwner;
    mapping(address => uint) public nonces; // mapping of addresses to their nonces

    address[] public owners; // all possible signers of each transaction
    uint public requiredSignatures; // minimum number of signatures required for execution of each transaction
    uint public transactionCount;

    // ===================
    //      Modifiers
    // ===================

    // modifiers serve as macros in C – they are substitued to the place of usage, while placeholder "_" represents the body of the function that uses them

    // TASK 2: replace the body of the following modifier to fit n-of-m multisig scheme while you verify:
    //     1. whether required signatures is at least 2 (would not be multisig anymore)
    //     2. the number of required signatures is not more than the number of owners

    modifier checkValidSettings(uint ownerCount, uint requiredSigs) {
        if (requiredSigs < 2 || ownerCount < requiredSigs) {
            revert("Validation of n-of-m multisig setting failed");
        }
        _;
    }

    modifier ownerExists(address owner) {
        if (!isOwner[owner]) {
            revert("Owner does not exist.");
        }
        _;
    }

    modifier transactionExists(uint transactionId) {
        if (transactions[transactionId].destination == address(0)) {
            revert("Transaction does not exit.");
        }
        _;
    }
    modifier confirmed(uint transactionId, address owner) {
        if (!signatures[transactionId][owner]) {
            revert("Confirmation of transaction by an owner does not exist.");
        }
        _;
    }
    modifier notConfirmed(uint transactionId, address owner) {
        if (signatures[transactionId][owner]) {
            revert("Transaction was already confirmed.");
        }
        _;
    }

    // TASK 1: implement a modifier that will protect against replay attacks. Use it at the correct place.

    modifier verifyTransactionNonce(uint transactionId) {
        if (transactions[transactionId].nonce != nonces[transactions[transactionId].sender]) {
            revert("Transaction nonce is invalid.");
        }
        _;
    }

    // ======================================================
    // Public functions callable from outside of the contract
    // ======================================================

    /// @dev Receive function – allows to deposit ETH by anybody just by sending the value to the address of the contract
    // 'msg.value' holds the amount of ETH sent in the current transaction and 'msg.sender' is the address of the sender of a transaction
    receive() external payable {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value); // emiting of the event is stored on the blockchain as well.
        }
    }

    /// @dev Constructor of n-of-m multisig wallet. It sets initial owners (i.e., signers) and minimal required number of signatures.
    /// @param _owners List of owners who can sign transactions.
    /// @param _requiredSigs The minimum number of required signatures.
    constructor(
        address[] memory _owners,
        uint _requiredSigs
    ) checkValidSettings(_owners.length, _requiredSigs) {
        // TASK 2: Modify this constructor to fit n-of-m scheme, i.e., an arbitrary number of owners and required signatures
        // do not allow repeating addresses or zero addresses to be passed as an owner

        for (uint i = 0; i < _owners.length; i++) {
            checkNotNull(_owners[i]);
            if (isOwner[_owners[i]]) {
                revert("A repeated owner passed.");
            }
            isOwner[_owners[i]] = true;
        }

        // save owners (m) and the minimum number of signatures (n) to the storage variables of the contract
        owners = _owners;
        requiredSignatures = _requiredSigs;
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ETH value.
    /// @return transactionId Sequential ID of a transaction.
    function submitTransaction(
        address destination,
        uint value
    ) public returns (uint transactionId) {
        transactionId = addTransaction(destination, value);
        confirmTransaction(transactionId);
        return transactionId;
    }

    /// @dev Allows an owner to confirm a transaction. Does not allow an owner to sign the same transaction twice.
    /// @param transactionId Sequential ID of a transaction.
    function confirmTransaction(
        uint transactionId
    )
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        signatures[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
    }

    /// @dev Returns the confirmation status of a transaction, i.e., do we have enough signatures already?
    /// @param transactionId Sequential ID of a transaction.
    /// @return isConfirmed True if the transaction has enough signatures and can be executed
    function isTransactionConfirmed(uint transactionId) public view returns (bool) {
        uint count = 0;

        for (uint i = 0; i < owners.length; i++) {
            if (signatures[transactionId][owners[i]]) {
                count += 1;
            }

            if (count == requiredSignatures) {
                return true;
            }
        }

        return false;
    }

    // TASK 3: check whether the contract has enough balance and if not then emit an event called NotEnoughBalance(curBalance, requestedBalance)

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Sequential ID of a transaction.
    function executeTransaction(uint transactionId) public verifyTransactionNonce(transactionId){
        if (isTransactionConfirmed(transactionId)) {
            Transaction storage transaction = transactions[transactionId];

            // check if the contract has enough balance
            uint256 currentBalance = address(this).balance;
            if (currentBalance < transaction.value) {
                emit NotEnoughBalance(currentBalance, transaction.value);
            }

            bool success = payable(address(uint160(transaction.destination))).send(
                transaction.value
            );

            if (success) {
                nonces[transaction.sender] += 1;
                emit Execution(transactionId);
            } else {
                emit ExecutionFailure(transactionId);
            }
        } else {
            revert("Transaction is not yet confirmed.");
        }
    }

    // ================================================================
    // Internal functions called only from inside of the smart contract
    // ================================================================

    function checkNotNull(address _address) internal pure {
        if (_address == address(0x0)) {
            revert("Address cannot be zero.");
        }
    }

    /// @dev Creates a new transaction of ETH sent from the wallet to the recipient. This function is not visible outside of the contract, submitTransaction function should be used instead.
    /// @param destination Address of the transaction recipient.
    /// @param value ETH value to be transfered.
    /// @return transactionId Sequential ID of a transaction.
    function addTransaction(
        address destination,
        uint value
    ) internal returns (uint transactionId) {
        checkNotNull(destination);
        transactionId = transactionCount;

        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            sender: msg.sender,
            nonce: nonces[msg.sender]
        });

        transactionCount += 1;
        emit Submission(transactionId);

        return transactionId;
    }

    // ===========================================================
    // Public functions for DAPP client (i.e., simulated by tests)
    // ===========================================================

    /// @dev Returns number of signatures of a transaction.
    /// @param transactionId Sequential ID of a transaction.
    /// @return count Number of signatures on a transaction.
    function getSignatureCount(
        uint transactionId
    ) public view returns (uint count) {
        for (uint i = 0; i < owners.length; i++) {
            if (signatures[transactionId][owners[i]]) {
                count += 1;
            }
        }

        return count;
    }

    /// @dev Returns list of all owners.
    /// @return owners List of owner addresses.
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    // TASK 4: implement a public read-only (not modifying the state) function that retrieves addresses of owners who signed a transaction

    /// @dev Returns array with owners that confirmed a transaction.
    /// @param transactionId Sequential ID of a transaction.
    /// @return signedOwners Array of owner addresses who signed the transaction.
    function getOwnersWhoSignedTx(
        uint transactionId
    ) public view returns (address[] memory signedOwners) {
        signedOwners = new address[](owners.length);
        uint count = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (signatures[transactionId][owners[i]]) {
                signedOwners[count] = owners[i];
                count++;
            }
        }
        // resize the array to the actual number of signed owners
        assembly {
            mstore(signedOwners, count)
        }
        return signedOwners;
    }
}
