// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Mercury is ERC20 {
    IERC721 NFTContract;
    uint256 public tokenID;
    IERC20 public token;
    address admin;
    uint256 public goal;
    uint256 interest;
    bool isPaid = false;
    uint256 maxSupply = 100000 ether;
    uint256 public deadline;

    modifier onlyOwner() {
        require(msg.sender == admin);
        _;
    }

    address[] lendersArray;
    mapping(address => uint256) lendersMap;
    mapping(address => uint256) burnersMap;

    constructor(
        address _admin,
        address tokenAddress,
        uint256 _goal,
        address NFTAddress,
        uint256 _tokenID,
        uint256 _interest,
        string memory name
    ) ERC20(string(abi.encodePacked("l_", name)), "MLT") {
        admin = _admin;
        token = IERC20(tokenAddress);
        goal = _goal;
        NFTContract = IERC721(NFTAddress);
        tokenID = _tokenID;
        interest = _interest;
        deadline = block.timestamp + 15 days;
    }

    function addLender(uint256 amount) public {
        require(token.balanceOf(address(this)) <= goal, "Goal Reached");
        require(
            NFTContract.balanceOf(address(this)) > 0,
            "NFT not in contract yet"
        );
        require(
            token.balanceOf(msg.sender) >= amount,
            "Insufficient Funds for Lending"
        );
        require(
            token.allowance(msg.sender, address(this)) >= amount,
            "Contract allowance insufficient"
        );
        require(
            totalSupply() + (amount / goal) * maxSupply <= maxSupply,
            "Liquidity not enough"
        );
        token.transferFrom(msg.sender, address(this), amount);
        lendersMap[msg.sender] = amount;
        lendersArray.push(msg.sender);
        _mint(msg.sender, (amount / goal) * maxSupply);
    }

    function adminWithdraw() public onlyOwner {
        require(block.timestamp >= deadline, "Lock-in period not over");
        token.transfer(admin, goal);
    }

    function repay() public onlyOwner {
        require(
            token.balanceOf(msg.sender) >= goal + (interest * goal) / 100,
            "Insufficient Funds with caller"
        );
        require(
            token.transferFrom(
                msg.sender,
                address(this),
                (goal + (interest * goal) / 100)
            ),
            "Token transfer unsuccessful"
        );
        isPaid = true;
        NFTContract.safeTransferFrom(address(this), admin, tokenID);
    }

    function payout() public {
        require(isPaid, "Admin hasn't paid debt");
        require(balanceOf(msg.sender) > 0, "Payout should be > 0");
        uint256 amount = (balanceOf(msg.sender) * goal) / 100;
        _burn(msg.sender, amount);
        lendersMap[msg.sender] = 0;
        token.transfer(msg.sender, amount + ((amount * interest) / 100));
    }

    function failSafeBurn() public {
        require(
            balanceOf(msg.sender) > 0,
            "Caller does not have receipt tokens"
        );
        uint256 balance = balanceOf(msg.sender);
        _burn(msg.sender, balance);
        burnersMap[msg.sender] = balance;
    }
}
