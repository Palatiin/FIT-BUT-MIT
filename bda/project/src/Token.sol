// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    uint256 public immutable MAX_SUPPLY;
    uint256 public immutable MAX_DAILY_MINT;

    uint256 private dailyMinted;
    uint256 private mintDailyLimitResetTimestamp;

    struct UserStatus {
        bool isVerified;
        bool isMintingAdmin;
        bool isIDPAdmin;
    }

    mapping(address => UserStatus) private userStatus;
    mapping(address => bool) private isTrustedIDP;
    address[] private trustedIDPList;

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
    ) ERC20("Token", "TKN") {
        MAX_SUPPLY = _maxSupply;
        for (uint256 i = 0; i < _mintingAdmins.length; i++) {
            checkNotNull(_mintingAdmins[i]);
            userStatus[_mintingAdmins[i]].isMintingAdmin = true;
        }
        MAX_DAILY_MINT = _maxDailyMint;
        for (uint256 i = 0; i < _trustedIdentityProviders.length; i++) {
            checkNotNull(_trustedIdentityProviders[i]);
            if (!isTrustedIDP[_trustedIdentityProviders[i]]) {
                trustedIDPList.push(_trustedIdentityProviders[i]);
            }
            isTrustedIDP[_trustedIdentityProviders[i]] = true;
        }
        for (uint256 i = 0; i < _idpAdmins.length; i++) {
            checkNotNull(_idpAdmins[i]);
            userStatus[_idpAdmins[i]].isIDPAdmin = true;
        }

        // Initialize the reset timestamp to the next midnight
        mintDailyLimitResetTimestamp = 0;
    }

    /**
     * T1.1, T1.2
     * @param to: address of the recipient
     * @param amount: amount of tokens to mint
     */
    function mint(address to, uint256 amount)
        public
        onlyMintingAdmin
        isVerified(to)
        updateDailyMintLimit
        checkDailyMintLimit(amount)
    {
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
    function transfer(address to, uint256 value)
        public
        override
        isVerified(_msgSender())
        isVerified(to)
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, value);
        emit TokensTransferred(owner, to, value);
        return true;
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    /**
     * T1.4:  Verify user identity using a signed message from a trusted IDP
     * @param timestamp The Unix timestamp when the identity was verified
     * @param signature The signature from the IDP
     */
    function verifyIdentity(uint256 timestamp, bytes memory signature) public {
        require(!userStatus[_msgSender()].isVerified, "Identity already verified");

        // Create the message that was signed
        bytes32 message = getMessageHash(_msgSender(), timestamp);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(message);

        // Recover the signer's address
        address signer = recoverSigner(ethSignedMessageHash, signature);

        // Check if the signer is a trusted IDP
        require(isTrustedIDP[signer], "Signature not from trusted IDP");

        // Mark user as verified
        userStatus[_msgSender()].isVerified = true;

        emit IdentityVerified(_msgSender(), timestamp);
    }

    /**
     * T1.5
     * @param _idp: address of the IDP to add
     */
    function addTrustedIDP(address _idp) public onlyIDPAdmin {
        require(!isTrustedIDP[_idp], "IDP already exists");
        if (!isTrustedIDP[_idp]) {
            trustedIDPList.push(_idp);
        }
        isTrustedIDP[_idp] = true;
        emit TrustedIDPAdded(_idp);
    }

    /**
     * T1.5
     * @param _idp: address of the IDP to remove
     */
    function removeTrustedIDP(address _idp) public onlyIDPAdmin {
        require(isTrustedIDP[_idp], "IDP not found");
        if (isTrustedIDP[_idp]) {
            uint256 idpListLength = trustedIDPList.length;
            for (uint256 i = 0; i < idpListLength; i++) {
                if (trustedIDPList[i] == _idp) {
                    delete trustedIDPList[i];
                    break;
                }
            }
        }
        isTrustedIDP[_idp] = false;
        emit TrustedIDPRemoved(_idp);
    }

    // ===== View Functions =====
    function getCurrentTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }

    function maxSupply() public view returns (uint256) {
        return MAX_SUPPLY;
    }

    function maxDailyMint() public view returns (uint256) {
        return MAX_DAILY_MINT;
    }

    function getTrustedIDPList() public view returns (address[] memory) {
        return trustedIDPList;
    }

    function checkTrustedIDP(address idp) public view returns (bool) {
        return isTrustedIDP[idp];
    }

    function getUserStatus(address user) public view returns (bool, bool, bool) {
        return (userStatus[user].isVerified, userStatus[user].isMintingAdmin, userStatus[user].isIDPAdmin);
    }

    function getDailyMintQuota() public view returns (uint256, uint256) {
        if (getCurrentTimestamp() >= mintDailyLimitResetTimestamp) {
            return (0, MAX_DAILY_MINT);
        }
        return (dailyMinted, MAX_DAILY_MINT);
    }

    function getNextMintLimitResetTimestamp() public view returns (uint256) {
        return mintDailyLimitResetTimestamp;
    }

    function getNextMidnightTimestamp() internal view returns (uint256) {
        uint256 currentTimestamp = getCurrentTimestamp();
        // Calculate seconds since midnight
        uint256 secondsSinceMidnight = currentTimestamp % 1 days;
        // Calculate timestamp for the next midnight
        return currentTimestamp + 1 days - secondsSinceMidnight;
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
        require(userStatus[_msgSender()].isMintingAdmin, "Not a minting admin");
        _;
    }

    modifier onlyIDPAdmin() {
        require(userStatus[_msgSender()].isIDPAdmin, "Not an IDP admin");
        _;
    }

    modifier updateDailyMintLimit() {
        uint256 currentTimestamp = getCurrentTimestamp();
        if (currentTimestamp >= mintDailyLimitResetTimestamp) {
            dailyMinted = 0;
            mintDailyLimitResetTimestamp = getNextMidnightTimestamp();
        }
        _;
    }

    modifier checkDailyMintLimit(uint256 amount) {
        require(dailyMinted + amount <= MAX_DAILY_MINT, "Max daily mint exceeded");
        _;
    }

    modifier isVerified(address user) {
        require(userStatus[user].isVerified, "User is not verified");
        _;
    }
}
