// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    uint256 public maxSupply;
    uint256 public maxDailyMint;

    mapping(address => bool) private isMintingAdmin;

    /**
    * T1.1: extend ERC20 constructor to initialize maxSupply
    * T1.2: mintingAdmin role, maxDailyMint
    *
    * @param _maxSupply: maximum supply of the token
    * @param _mintingAdmins: array of addresses that are minting admins
    * @param _maxDailyMint: maximum amount of tokens that can be minted in a day
    */
    constructor(uint256 _maxSupply, address[] memory _mintingAdmins, uint256 _maxDailyMint) ERC20("Token", "TKN") {
        maxSupply = _maxSupply;
        for (uint i = 0; i < _mintingAdmins.length; i++) {
            checkNotNull(_mintingAdmins[i]);
            isMintingAdmin[_mintingAdmins[i]] = true;
        }
        maxDailyMint = _maxDailyMint;
    }

    function checkNotNull(address _address) internal pure {
        if (_address == address(0x0)) {
            revert("Address cannot be zero.");
        }
    }
}