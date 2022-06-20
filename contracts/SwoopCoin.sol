// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract SaleCreator {
    address private owner;
    address[] private finishedSales; //this is really not necessary. but project assignment required it...
    mapping(address => mapping(string => address)) merchantSales;
    uint256 public commission = 5; //in Wei
    uint256 public cancelCommission = 5; //in Wei

    constructor() {
        owner = msg.sender;
    }

    function changeCommission(
        uint256 newCommission,
        uint256 newCancelCommission
    ) external onlyOwner {
        commission = newCommission;
        cancelCommission = newCancelCommission;
    }

    event SaleCreated(address);

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "You are not authorized to call this method."
        );
        _;
    }

    function createSale(Sale memory _sale) external payable returns (address) {
        require(
            msg.value == commission,
            "Commission amount not equal to specified amount. Aborting."
        );
        require(
            merchantSales[msg.sender][_sale.saleCode] == address(0),
            "The sale already exists for the sale code provided."
        );

        address newSale = address(
            new SaleContract(msg.sender, cancelCommission, _sale)
        );
        merchantSales[msg.sender][_sale.saleCode] = newSale;

        emit SaleCreated(newSale);

        return newSale;
    }

    function saleFinished(string memory saleCode, address store) public {
        require(
            merchantSales[store][saleCode] == msg.sender,
            string.concat("Sale does not exist: ", saleCode)
        );

        finishedSales.push(msg.sender);
    }

    function receiveCancelCommission() external payable {}

    function projectSubmitted(
        string memory _codeHash,
        string memory _authorName,
        address _sendHashTo
    ) external onlyOwner {
        (bool isSuccessful, bytes memory returnData) = address(_sendHashTo)
            .call{value: 0}(
            abi.encodeWithSignature(
                "recieveProjectData(string,string)",
                _codeHash,
                _authorName
            )
        );
        if (!isSuccessful) revert(string(returnData));
    }

    receive() external payable {
        revert(
            "Call defaulted to 'receive'. Make a call to with a function name."
        ); //so that merchants only call 'createSale'
    }

    fallback() external payable {
        revert(
            "Call defaulted to 'fallback'. Make a call to with a function name."
        ); //so that merchants only call 'createSale'
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
    uint256 public cancelCommission; //in Wei

    constructor(
        address _store,
        uint256 _cancelCommission,
        Sale memory _sale
    ) {
        require(_sale.price > 0, "Sale price can not be zero or negative.");

        master = msg.sender;
        cancelCommission = _cancelCommission;
        store = _store;
        sale = _sale;
    }

    event DepositReceived(address);
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

        emit DepositReceived(msg.sender);

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
            clients[msg.sender] == true,
            "You are not a depositor or already have been refunded. You can not get refunded."
        );
        require(
            !isSaleTargetReached(),
            "Sale has already reached minimum number of required users. You can not get refunded any longer."
        );
        //require(isSaleExpired(), "Sale has not expired yet.");

        payingClientCount--;
        clients[msg.sender] = false; // pattern: checks effects interaction

        payable(msg.sender).transfer(sale.price);
    }

    function withdraw() external isStoreOwner {
        require(
            isSaleTargetReached(),
            "Sale has not reached minimum number of required users."
        );

        bool isSent = payable(msg.sender).send(sale.price * payingClientCount);
        if (!isSent) revert("Error paying the store owner");

        (bool isSuccessful, bytes memory returnData) = master.call{value: 0}(
            abi.encodeWithSignature(
                "saleFinished(string,address)",
                sale.saleCode,
                store
            )
        ); // an example of call call
        if (!isSuccessful) revert(string(returnData));
    }

    function cancelSale() external payable isStoreOwner {
        require(
            msg.value == cancelCommission,
            "Cancel commission amount not sent. Aborting."
        );

        (SaleCreator(payable(master))).receiveCancelCommission{
            value: msg.value
        }(); //an example of named call
    }
}
