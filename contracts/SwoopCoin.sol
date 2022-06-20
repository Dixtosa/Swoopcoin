// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract SaleCreator {
    address[] private finishedSales;
    mapping(address => mapping(string => address)) merchantSales;
    uint256 public commission = 5; //in Wei
    uint256 public cancelCommission = 5; //in Wei

    constructor() {}

    function changeCommission(uint256 newCommission) external {
        commission = newCommission;
    }

    event SaleCreated(address);

    function createSale(Sale memory _sale) external payable returns (address) {
        require(
            msg.value == commission,
            "Commission amount not equal to specified amount. Aborting."
        );
        require(
            merchantSales[msg.sender][_sale.saleCode] == address(0),
            "The sale already exists for the sale code provided."
        );

        address newSale = address(new SaleContract(msg.sender, _sale));

        emit SaleCreated(newSale);

        return newSale;
    }

    function saleFinished(string memory saleCode) public {
        require(
            merchantSales[msg.sender][saleCode] != address(0),
            "Sale does not exist."
        );

        finishedSales.push(msg.sender);
    }

    receive() external payable {
        revert("Call defaulted to 'receive'. Call createScale function."); //so that merchants only call 'createSale'
    }

    fallback() external payable {
        revert("Call defaulted to 'fallback'. Call createScale function."); //so that merchants only call 'createSale'
    }
}

struct Sale {
    string saleCode;
    uint256 price;
    uint256 endDate;
    uint32 minNumberOfClients;
}

contract SaleContract {
    address public master;
    address public store;
    Sale public sale;
    mapping(address => bool) private clients;
    uint32 public payingClientCount = 0;
    bool private saleExpired = false;
    uint256 public cancelCommission = 5; //in Wei

    constructor(address _store, Sale memory _sale) {
        require(_sale.price > 0, "Sale price can not be zero or negative.");

        master = msg.sender;
        store = _store;
        sale = _sale;
    }

    event SaleTargetReached();

    receive() external payable {
        require(clients[msg.sender] == false, "You have already payed.");
        require(msg.value == sale.price, "Sent Ether is not equal to price.");
        require(
            !isSaleTargetReached(),
            "Sale has already reached minimum number of required users."
        );
        require(!isSaleExpired(), "Sale has expired.");

        //balances[msg.sender] += msg.value;
        clients[msg.sender] = true;

        payingClientCount++;

        if (isSaleTargetReached()) emit SaleTargetReached();
    }

    function isSaleExpired() private view returns (bool) {
        //require (!saleTargetReached(), "Sale has already reached minimum number of required users.");
        //require (block.timestamp > sale.endDate);

        return block.timestamp >= sale.endDate; //todo: take 900 seconds into account?
    }

    function isSaleTargetReached() public view returns (bool) {
        return (payingClientCount == sale.minNumberOfClients);
    }

    modifier isStoreOwner() {
        require(
            msg.sender == store,
            "You are not authorized to call this method."
        );
        _;
    }

    //pattern: pull instead of push
    function retrieveRefund() external {
        require(
            !isSaleTargetReached(),
            "Sale has already reached minimum number of required users. You can not get refunded any longer."
        );
        require(isSaleExpired(), "Sale has not expired yet.");
        require(
            clients[msg.sender] == true,
            "You are not a depositor or already have been refunded. You can not get refunded."
        );

        clients[msg.sender] = false; // pattern: checks effects interaction

        payable(msg.sender).transfer(sale.price);
    }

    function withdraw() external isStoreOwner {
        require(
            isSaleTargetReached(),
            "Sale has not reached minimum number of required users."
        );

        bool isSent = payable(msg.sender).send(sale.price * payingClientCount);

        if (isSent) (SaleCreator(payable(master))).saleFinished(sale.saleCode);
        else revert();
        //require(isSent, "withdraw unsuccessful.");
    }

    function cancelSale() external payable isStoreOwner {
        require(
            msg.value == cancelCommission,
            "Commission amount not sent. Aborting."
        );

        (bool isSuccessful, ) = master.call{value: msg.value}("");

        require(isSuccessful, "cancelSale unsuccessful.");
    }
}
