const SaleCreator = artifacts.require("SaleCreator");

module.exports = function (deployer) {
    deployer.deploy(SaleCreator);
};
