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
            minNumberOfClients: 3
        }, { value: 5 });

        console.log(res.logs);
        var saleInstance = await SaleContract.at(res.logs[0].args["0"]);
        console.log(await saleInstance.sale());
        console.log((await web3.eth.getBalance(instance.address)) + ":" + await web3.eth.getBalance(saleInstance.address));
        res = await saleInstance.sendTransaction({ value: 1000 });
        console.log((await web3.eth.getBalance(instance.address)) + ":" + await web3.eth.getBalance(saleInstance.address));
        //console.log(await saleInstance.payingClientCount());
        res = await saleInstance.sendTransaction({ value: 1000, from: accounts[1] });
        console.log((await web3.eth.getBalance(instance.address)) + ":" + await web3.eth.getBalance(saleInstance.address));
        //console.log(await saleInstance.payingClientCount());
        res = await saleInstance.sendTransaction({ value: 1000, from: accounts[2] });
        //console.log(res.logs);
        //res = await saleInstance.retrieveRefund({ from: accounts[1] });
        //console.log((await web3.eth.getBalance(instance.address)) + ":" + await web3.eth.getBalance(saleInstance.address));
        //console.log(await saleInstance.payingClientCount());
        //await saleInstance.cancelSale({ value: 5 });
        res = await saleInstance.withdraw();
        console.log(res.logs);
        console.log((await web3.eth.getBalance(instance.address)) + ":" + await web3.eth.getBalance(saleInstance.address));
    })
});