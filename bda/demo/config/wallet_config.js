// You can adjust these two parameters of tests to your n-of-m multisig wallet contract

var MultiSigWalletConf = Object.freeze({
    NUMBER_OF_OWNERS: 3, // m
    REQUIRED_SIGS: 2, // n
})

module.exports = MultiSigWalletConf;