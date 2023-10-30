// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title LoanContract for issuing and managing loans against NFT collateral
/// @notice This contract handles the creation, tracking, and repayment of loans, including interest rate computation
/// @dev This contract assumes a simple fixed interest model for demonstration purposes
contract LoanContract is Ownable(msg.sender) {
    using SafeMath for uint256;

    struct Loan {
        uint256 depositId;      // ID of the NFT deposit used as collateral
        address borrower;       // Address of the borrower
        uint256 principal;      // Principal amount of the loan
        uint256 interestRate;   // Interest rate (annual)
        uint256 loanStart;      // Start time of the loan
        uint256 duration;       // Duration of the loan in seconds
        bool isRepaid;          // Flag to track if loan is repaid
    }

    uint256 public nextLoanId;
    mapping(uint256 => Loan) public loans;

    event LoanCreated(uint256 indexed loanId, uint256 indexed depositId, address indexed borrower, uint256 principal, uint256 interestRate, uint256 duration);
    event LoanRepaid(uint256 indexed loanId, uint256 repaidAmount);

    /// @notice Creates a loan for a given NFT deposit
    /// @param depositId The ID of the NFT deposit being used as collateral
    /// @param principal The principal amount of the loan
    /// @param interestRate The annual interest rate
    /// @param duration The loan duration in seconds
    /// @return loanId The unique ID of the created loan
    function createLoan(uint256 depositId, uint256 principal, uint256 interestRate, uint256 duration) external returns (uint256 loanId) {
        loanId = nextLoanId++;
        loans[loanId] = Loan(depositId, msg.sender, principal, interestRate, block.timestamp, duration, false);
        emit LoanCreated(loanId, depositId, msg.sender, principal, interestRate, duration);
        return loanId;
    }

    /// @notice Repays a loan and releases the NFT collateral
    /// @dev This simple example doesn't handle transferring funds or NFTs
    /// @param loanId The ID of the loan being repaid
    function repayLoan(uint256 loanId) external {
        Loan storage loan = loans[loanId];
        require(msg.sender == loan.borrower, "Only borrower can repay the loan");
        require(!loan.isRepaid, "Loan is already repaid");

        uint256 owedAmount = calculateTotalOwed(loanId);
        // In a real contract, transfer of funds would be handled here

        loan.isRepaid = true;
        emit LoanRepaid(loanId, owedAmount);

        // Release NFT collateral
        // This would typically call back to the NFTCollateralContract to release the NFT to the borrower
    }

    /// @notice Calculates the total amount owed for a loan, including interest
    /// @param loanId The ID of the loan
    /// @return The total amount owed
    function calculateTotalOwed(uint256 loanId) public view returns (uint256) {
        Loan storage loan = loans[loanId];
        uint256 timeElapsed = block.timestamp - loan.loanStart;
        uint256 interest = (loan.principal.mul(loan.interestRate).mul(timeElapsed)).div(365 days).div(100);
        return loan.principal.add(interest);
    }
}
