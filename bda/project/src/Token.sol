// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    uint256 public immutable MAX_SUPPLY;
    uint256 public immutable MAX_DAILY_MINT;

    uint256 public dailyMinted;
    uint256 public mintDailyLimitResetTimestamp;

    mapping(address => bool) public isTrustedIDP;

    mapping(address => bool) private isMintingAdmin;
    mapping(address => bool) private isIDPAdmin;
    mapping(address => bool) private userVerificationStatus;

    event IdentityVerified(address indexed user, uint256 timestamp);
    event TokensMinted(address indexed minter, address indexed to, uint256 amount);
    event TokensTransferred(address indexed from, address indexed to, uint256 amount);
    event TrustedIDPAdded(address indexed idp);
    event TrustedIDPRemoved(address indexed idp);

    /**
     * T1.1: extend ERC20 constructor to initialize MAX_SUPPLY 
     * T1.2: mintingAdmin role, maxDailyMint
     * T1.4: trustedIdentityProviders
     * T1.5: idpAdmin role
     * @param _maxSupply: maximum supply of the token
     * @param _mintingAdmins: array of addresses that are minting admins
     * @param _maxDailyMint: maximum amount of tokens that can be minted in a day
     */
    constructor(
        uint256 _maxSupply,
        address[] memory _mintingAdmins,
        uint256 _maxDailyMint,
        address[] memory _trustedIdentityProviders,
        address[] memory _idpAdmins
    ) ERC20("Token", "TKN")
    {
        MAX_SUPPLY = _maxSupply;
        for (uint i = 0; i < _mintingAdmins.length; i++) {
            checkNotNull(_mintingAdmins[i]);
            isMintingAdmin[_mintingAdmins[i]] = true;
        }
        MAX_DAILY_MINT = _maxDailyMint;
        for (uint i = 0; i < _trustedIdentityProviders.length; i++) {
            checkNotNull(_trustedIdentityProviders[i]);
            isTrustedIDP[_trustedIdentityProviders[i]] = true;
        }
        for (uint i = 0; i < _idpAdmins.length; i++) {
            checkNotNull(_idpAdmins[i]);
            isIDPAdmin[_idpAdmins[i]] = true;
        }
    }

    /**
     * T1.1, T1.2
     * @param to: address of the recipient
     * @param amount: amount of tokens to mint
     */
    function mint(address to, uint256 amount) public onlyMintingAdmin isVerified(to) checkDailyMintLimit(amount) {
        require(totalSupply() + amount <= MAX_SUPPLY, "Max supply exceeded");

        _mint(to, amount);
        dailyMinted += amount;
        emit TokensMinted(_msgSender(), to, amount);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public override isVerified(_msgSender()) isVerified(to) returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        emit TokensTransferred(owner, to, value);
        return true;
    }

    /**
     * T1.4:  Verify user identity using a signed message from a trusted IDP
     * @param timestamp The Unix timestamp when the identity was verified
     * @param signature The signature from the IDP
     */
    function verifyIdentity(uint256 timestamp, bytes memory signature) public {
        require(!userVerificationStatus[_msgSender()], "Identity already verified");
        
        // Create the message that was signed
        bytes32 message = getMessageHash(_msgSender(), timestamp);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(message);
        
        // Recover the signer's address
        address signer = recoverSigner(ethSignedMessageHash, signature);
        
        // Check if the signer is a trusted IDP
        require(isTrustedIDP[signer], "Signature not from trusted IDP");
        
        // Mark user as verified
        userVerificationStatus[_msgSender()] = true;
        
        emit IdentityVerified(_msgSender(), timestamp);
    }

    /**
     * T1.5
     * @param _idp: address of the IDP to add
     */
    function addTrustedIDP(address _idp) public onlyIDPAdmin {
        isTrustedIDP[_idp] = true;
        emit TrustedIDPAdded(_idp);
    }

    /**
     * T1.5
     * @param _idp: address of the IDP to remove
     */
    function removeTrustedIDP(address _idp) public onlyIDPAdmin {
        isTrustedIDP[_idp] = false;
        emit TrustedIDPRemoved(_idp);
    }

    // ===== View Functions =====
    function getCurrentTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }

    // ===== Pure Functions =====
    function checkNotNull(address _address) internal pure {
        if (_address == address(0x0)) {
            revert("Address cannot be zero.");
        }
    }

    /**
     * T1.4
     * @dev Create a message hash to be signed by the IDP
     * @param user The user address
     * @param timestamp The verification timestamp
     * @return bytes32 The message hash
     */
    function getMessageHash(address user, uint256 timestamp) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("User with address ", user, " has verified their identity at ", timestamp));
    }

    /**
     * @dev Create an Ethereum signed message hash
     * @param messageHash The message hash to convert
     * @return bytes32 The Ethereum signed message hash
     */
    function getEthSignedMessageHash(bytes32 messageHash) internal pure returns (bytes32) {
        // This recreates the signature that is created by ethers.js hashMessage
        // Prefix with "\x19Ethereum Signed Message:\n32"
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }

    /**
     * T1.4
     * @dev Recover signer address from a signature
     * @param ethSignedMessageHash The Ethereum signed message hash
     * @param signature The signature to verify
     * @return address The address of the signer
     */
    function recoverSigner(bytes32 ethSignedMessageHash, bytes memory signature) internal pure returns (address) {
        require(signature.length == 65, "Invalid signature length");
        
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        
        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    // ===== Modifiers =====
    modifier onlyMintingAdmin() {
        require(isMintingAdmin[_msgSender()], "Not a minting admin");
        _;
    }

    modifier onlyIDPAdmin() {
        require(isIDPAdmin[_msgSender()], "Not an IDP admin");
        _;
    }

    modifier checkDailyMintLimit(uint256 amount) {
        if (getCurrentTimestamp() >= mintDailyLimitResetTimestamp) {
            dailyMinted = 0;
            mintDailyLimitResetTimestamp = getCurrentTimestamp() + 1 days;
        }
        require(dailyMinted + amount <= MAX_DAILY_MINT, "Max daily mint exceeded");
        _;
    }

    modifier isVerified(address user) {
        require(userVerificationStatus[user], "User is not verified");
        _;
    }
}