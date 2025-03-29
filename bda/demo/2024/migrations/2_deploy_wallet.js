var W3 = require('web3');
var MultiSigWallet = artifacts.require("MultiSigWallet");
MAX_NUMBER_OF_OWNERS = 10

// load parameters of multisig wallet from config file
var conf = require("../config/wallet_config.js");

module.exports = function(deployer, network, accounts) {
    var owners = []

    if (conf.NUMBER_OF_OWNERS > MAX_NUMBER_OF_OWNERS) {
        throw "The number of owners is bigger than maximum"
    }

    if (network == "mainnet") {
        throw "Halt. Sanity check. Not ready for deployment to mainnet.";
    } else if (network == "sepolia" || network == "sepolia-fork") {
        owners.push("0xA740d1c5eF3E61773293D5E8860Fb6575dF25E6d")
        owners.push("0xB5902F7b07d5C8f992aBad01796483a67FAe8dDd")
        owners.push("0xca8f65998258190ededda8a256a12688d7D911D2")
    } else { // development & test networks
        for (let i = 0; i < conf.NUMBER_OF_OWNERS; i++) {
            owners.push(accounts[i])
        }
    }

    console.log('Deploying MultiSigWallet to network', network);
    console.log("\t --owners: ", owners,
        ";\n\t --required signatures", conf.REQUIRED_SIGS
    );

    // anybody can deploy contract - e.g., address[0]
    result = deployer.deploy(MultiSigWallet, owners, conf.REQUIRED_SIGS, { from: accounts[0], gas: 2 * 1000 * 1000 }).then(() => {
        console.log('Deployed MultiSigWallet with address', MultiSigWallet.address);
        console.log("\t \\/== Default gas limit:", MultiSigWallet.class_defaults.gas);
    });
};


// NOTES
//
// var W3 = require('web3');
//
// MultiSigWallet.deployed().then(function(instance){return instance.getOwners()});
// MultiSigWallet.deployed().then(function(instance){return instance.getOwners.call()});

// Access migrated instance of contract
// MultiSigWallet.deployed().then(function(instance) {console.log(instance); });

// Get balance of contract
// W3.utils.fromWei(web3.eth.getBalance('... some address of contract...').toString(), 'ether');