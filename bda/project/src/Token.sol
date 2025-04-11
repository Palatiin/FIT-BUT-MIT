// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    uint256 public immutable MAX_SUPPLY;
    uint256 public immutable MAX_DAILY_MINT;

    uint256 public dailyMinted;
    uint256 public mintDailyLimitResetTimestamp;

    mapping(address => bool) private isMintingAdmin;

    /**
    * T1.1: extend ERC20 constructor to initialize MAX_SUPPLY 
    * T1.2: mintingAdmin role, maxDailyMint
    *
    * @param _maxSupply: maximum supply of the token
    * @param _mintingAdmins: array of addresses that are minting admins
    * @param _maxDailyMint: maximum amount of tokens that can be minted in a day
    */
    constructor(uint256 _maxSupply, address[] memory _mintingAdmins, uint256 _maxDailyMint) ERC20("Token", "TKN") {
        MAX_SUPPLY = _maxSupply;
        for (uint i = 0; i < _mintingAdmins.length; i++) {
            checkNotNull(_mintingAdmins[i]);
            isMintingAdmin[_mintingAdmins[i]] = true;
        }
        MAX_DAILY_MINT = _maxDailyMint;
    }

    /**
    * T1.1, T1.2
    *
    * @param to: address of the recipient
    * @param amount: amount of tokens to mint
    */
    function mint(address to, uint256 amount) public onlyMintingAdmin checkDailyMintLimit(amount) {
        require(totalSupply() + amount <= MAX_SUPPLY, "Max supply exceeded");

        _mint(to, amount);
        dailyMinted += amount;
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

    // ===== Modifiers =====
    modifier onlyMintingAdmin() {
        require(isMintingAdmin[_msgSender()], "Not a minting admin");
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
}