// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Mercury {
    IERC721 NFTContract;
    uint256 tokenID;
    IERC20 token;
    address admin;
    uint256 goal;
    uint256 interest;

    modifier onlyOwner() {
        require(msg.sender == admin);
        _;
    }

    struct Lender {
        address lenderAddress;
        uint256 amount;
    }

    address[] lendersArray;
    mapping(address => uint256) lendersMap;

    constructor(
        address _admin,
        address tokenAddress,
        uint256 _goal,
        address NFTAddress,
        uint256 _tokenID,
        uint256 _interest
    ) {
        admin = _admin;
        token = IERC20(tokenAddress);
        goal = _goal;
        NFTContract = IERC721(NFTAddress);
        tokenID = _tokenID;
        interest = _interest;
    }

    function addLender(uint256 amount) public {
        require(token.balanceOf(address(this)) >= goal, "Goal Reached");
        require(
            NFTContract.balanceOf(address(this)) > 0,
            "NFT not in contract yet"
        );
        require(
            token.balanceOf(msg.sender) > amount,
            "Insufficient Funds for Lending"
        );
        require(
            token.allowance(msg.sender, address(this)) > amount,
            "Contract allowance insufficient"
        );
        token.transferFrom(msg.sender, admin, amount);
        lendersMap[msg.sender] = amount;
        lendersArray.push(msg.sender);
    }

    function repay() public onlyOwner {
        require(
            token.balanceOf(address(this)) >= goal + (interest * goal) / 100,
            "Insufficient Funds for withdrawal"
        );
        for (uint256 i = 0; i <= lendersArray.length; i++) {
            uint256 tempAmount = lendersMap[lendersArray[i]];
            token.transfer(
                lendersArray[i],
                (tempAmount + (interest * tempAmount) / 100)
            );
        }
    }
}
