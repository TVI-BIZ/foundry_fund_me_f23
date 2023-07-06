// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
//import "@openzeppelin/contracts/utils/math/SafeMath.sol";

//import {getVersion} from "./PriceConverter.sol";
import {PriceConverter} from "./PriceConverter.sol";
import {PriceConverter} from "./PriceConverter.sol";

//868276
//
error FundMe__NotOwner();

contract FundMe {
    //using SafeMath for uint256;
    using PriceConverter for uint256;

    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;
    address private immutable owner;
    uint256 public constant minimumUSD = 5 * 10 ** 18;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) public {
        owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        // $50

        require(
            msg.value.getConversionRate(s_priceFeed) >= minimumUSD,
            "You need to spend more ETH!"
        );
        //require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH!");
        //require(msg.value > 1e18,"Not Enough Ether");
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
        //what ETH-> USD rate
    }

    modifier onlyOwner() {
        //require(msg.sender == owner);
        if (msg.sender != owner) revert FundMe__NotOwner();
        _;
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function cheaperWithdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length;

        for (
            uint256 funderIndex = 0;
            funderIndex < fundersLength;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }(""); // best way today
        require(callSuccess, "Send failed");
    }

    function withdraw() public payable onlyOwner {
        //msg.sender.transfer(address(this).balance);
        // require msg.sen
        payable(msg.sender).transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        //transfer
        //payable(msg.sender).transfer(address(this).balance); //max 22000 gas
        //send
        //bool sendsucess = payable(msg.sender).send(address(this).balance); //max 23000 gas
        //require(sendSuccess,"Send failed");
        //call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }(""); // best way today
        require(callSuccess, "Send failed");
    }

    //receive()
    //fallback()
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}
