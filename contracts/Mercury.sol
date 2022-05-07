// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Mercury is ERC20 {

    IERC721 NFTContract;
    uint tokenID;
    IERC20 token;
    address admin;
    uint goal;
    uint interest;
    bool isPaid = false;
    uint maxSupply = 100000 ether;

    modifier onlyOwner {
        require(msg.sender == admin);
        _;
    }

    address[] lendersArray; 
    mapping(address => uint) lendersMap;
    mapping(address => uint) burnersMap;

    constructor(address _admin, address tokenAddress, uint _goal, address NFTAddress, uint _tokenID, uint _interest, string memory name) ERC20(string(abi.encodePacked("l_", name)), "MLT") {
        admin = _admin;
        token = IERC20(tokenAddress);
        goal = _goal;
        NFTContract = IERC721(NFTAddress);
        tokenID = _tokenID;
        interest = _interest;
    }

    function addLender(uint amount) public {
        require(token.balanceOf(address(this)) <= goal, "Goal Reached");
        require(NFTContract.balanceOf(address(this)) > 0, "NFT not in contract yet");
        require(token.balanceOf(msg.sender) >= amount, "Insufficient Funds for Lending");
        require(token.allowance(msg.sender, address(this)) >= amount, "Contract allowance insufficient");
        require(totalSupply() + (amount / goal) * maxSupply <= maxSupply, "Liquidity not enough");
        token.transferFrom(msg.sender, admin, amount);
        lendersMap[msg.sender] = amount;
        lendersArray.push(msg.sender);
        _mint(msg.sender, (amount / goal) * maxSupply);
    }

    function repay() public onlyOwner {
        require(token.balanceOf(msg.sender) >= goal + (interest * goal) / 100, "Insufficient Funds with caller");
        token.transferFrom(msg.sender, address(this), goal + (interest * goal) / 100);
        require(token.balanceOf(msg.sender) >= goal + (interest * goal) / 100, "Insufficient Funds for withdrawal");
        isPaid = true;
        NFTContract.safeTransferFrom(address(this), admin, tokenID);
    }

    function payout() public {
        require(isPaid, "Admin hasn't paid debt");
        require(balanceOf(msg.sender) > 0, "Payout should be > 0");
        uint amount = (balanceOf(msg.sender) * goal) / 100;
        _burn(msg.sender, amount);
        lendersMap[msg.sender] = 0;
        token.transfer(msg.sender, amount + ((amount * interest) / 100));
    }

    function failSafeBurn() public {
        require(balanceOf(msg.sender) > 0, "Does not have receipt tokens");
        uint balance = balanceOf(msg.sender);
        _burn(msg.sender, balance);
        burnersMap[msg.sender] = balance;
    }
}