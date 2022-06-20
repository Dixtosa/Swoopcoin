const SaleCreator = artifacts.require("SaleCreator");
const SaleContract = artifacts.require("SaleContract");

const now = new Date();
const secondsSinceEpoch = Math.round(now.getTime() / 1000);

contract("SaleCreator", accounts => {
    it("test1", async () => {
        let instance = await SaleCreator.deployed();
        let res = await instance.createSale({
            saleCode: "saleCode1",
            price: 1000,
            endDate: secondsSinceEpoch + 10,
            minNumberOfClients: 10
        }, { value: 5 });
        console.log(res.logs);
        var saleInstance = await SaleContract.at(res.logs[0].args["0"]);
        //console.log(saleInstance);
        console.log(await saleInstance.payingClientCount());
        res = await saleInstance.sendTransaction({ value: 1000 });
        saleInstance = await SaleContract.at(res.logs);
    })
});