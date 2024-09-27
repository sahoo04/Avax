// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FundRaising {

    // State variables
    address public owner;
    uint public totalFunds;
    mapping(address => uint) public contributions;
    address public idoAddress;

    // Events
    event FundReceived(address indexed sender, uint amount);
    event FundsSentToIDO(address indexed idoAddress, uint amount);

    // Constructor to initialize the contract owner and IDO address
    constructor(address _idoAddress) {
        require(_idoAddress != address(0), "IDO address cannot be zero address");
        owner = msg.sender; // Address deploying the contract is the owner
        idoAddress = _idoAddress; // Set the IDO address to the provided address
    }

    // Modifier to restrict access to the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    // Fallback function to handle direct ether transfers
    receive() external payable {
        contribute();
    }

    // Function for users to contribute to the fundraising campaign
    function contribute() public payable {
        require(msg.value > 0, "Contribution must be greater than 0");
        contributions[msg.sender] += msg.value;
        totalFunds += msg.value;

        emit FundReceived(msg.sender, msg.value);
    }

    // Function to send collected funds to the IDO with a callback
    function sendFundsToIDO() public onlyOwner {
        require(totalFunds > 0, "No funds available");
        require(idoAddress != address(0), "IDO address not set");

        uint amount = totalFunds;
        totalFunds = 0;

        (bool success, ) = idoAddress.call{value: amount}("");
        require(success, "Transfer failed");

        // Callback to the IDO contract (if needed)
        IIDOCallback(idoAddress).onFundsReceived{value: amount}(address(this), amount);

        emit FundsSentToIDO(idoAddress, amount);
    }

    // Function to update the IDO address
    function updateIDOAddress(address _idoAddress) public onlyOwner {
        require(_idoAddress != address(0), "IDO address cannot be zero address");
        idoAddress = _idoAddress;
    }
}

// Interface for the IDO contract to handle callbacks
interface IIDOCallback {
    function onFundsReceived(address sender, uint amount) external payable;
}