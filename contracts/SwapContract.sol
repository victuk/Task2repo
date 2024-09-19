// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Lock {

    uint256 swapCount;

    address owner;

    enum SwapStatus {
        pendng,
        completed,
        cancelled
    }

    struct swapStruct {
        uint256 depositAmount;
        uint256 withdrawAmount;
        SwapStatus status;
        address depositAddress;
        address receiverAddress;
        address baseToken;
        address swapToken;
        string[2] depositorCurrency;
        string[2] receiverCurrency;
        uint256 createdAt;
        uint256 updatedAt;
    }

    mapping (uint => swapStruct) Swaps;

    modifier onlyOwner {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function transferToken(address _tokenAddress, address _to, uint256 _amount) external {
        require(_to != address(0), "You you are not allowed to burn this token");
        require(msg.sender != address(0), "Address zero detected");
        require(IERC20(_tokenAddress).balanceOf(msg.sender) >= _amount, "Insufficient fund");


        bool transferResult = IERC20(_tokenAddress).transfer(_to, _amount);

        require(transferResult, "Transfer not complete");
    }

    function createSwap(
        uint256 _depositAmount,
        uint256 _withdrawAmount,
        SwapStatus _status,
        address _depositAddress,
        address _receiverAddress,
        address _baseToken,
        address _swapToken,
        string[2] memory _depositorCurrency
    ) external {

        require(msg.sender != address(0), "Address zero detected");

        bool transferCompleted = IERC20(_baseToken).transferFrom(msg.sender, address(this), _depositAmount);

        require(transferCompleted, "Transfer failed");

        swapCount += 1;

        Swaps[swapCount] = swapStruct(
            _depositAmount,
            _withdrawAmount,
            _status,
            _depositAddress,
            address(0),
            _baseToken,
            _swapToken,
            _depositorCurrency,
            ["", ""],
            block.timestamp,
            0
        );
    }

    function swapToken(uint256 swapId) external {
        require(msg.sender != address(0), "Address zero detected");

        swapStruct memory singleSwap = Swaps[swapId];

        require(singleSwap.status != SwapStatus.completed, "This swap has been completed already");
        require(singleSwap.status != SwapStatus.cancelled, "This swap was cancelled");

        uint256 buyerBalance = IERC20(singleSwap.swapToken).balanceOf(msg.sender);

        require(singleSwap.withdrawAmount <= buyerBalance, "You don't have sufficient funds");

        bool transferResult = IERC20(singleSwap.swapToken).transferFrom(msg.sender, singleSwap.depositAddress, singleSwap.withdrawAmount);

        require(transferResult, "Transfer request failed.");

        bool transferResult2 = IERC20(singleSwap.baseToken).transfer(msg.sender, singleSwap.depositAmount);

        require(transferResult2, "Transfer failed.");

    }

}
