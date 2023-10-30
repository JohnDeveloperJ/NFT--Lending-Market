// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title LTVManager
/// @notice Manages the Loan-to-Value (LTV) ratio for loans, dynamically adjusting based on the collateral's valuation
/// @dev This contract is a simplified version and needs actual integration with a valuation oracle or similar
contract LTVManager {
    // Mapping of collateral ID to its current LTV ratio
    mapping(uint256 => uint256) private collateralLTV;

    // Event emitted when the LTV ratio of a collateral is updated
    event LTVUpdated(uint256 collateralId, uint256 newLTV);

    /// @notice Updates the LTV ratio for a given piece of collateral
    /// @param collateralId The ID of the collateral
    /// @param newLTV The new LTV ratio for the collateral
    function updateLTV(uint256 collateralId, uint256 newLTV) public {
        // In a real-world scenario, ensure only authorized parties (like admin or oracle) can update the LTV
        require(newLTV > 0, "LTV must be greater than 0");
        collateralLTV[collateralId] = newLTV;
        emit LTVUpdated(collateralId, newLTV);
    }

    /// @notice Gets the current LTV ratio for a given piece of collateral
    /// @param collateralId The ID of the collateral
    /// @return The LTV ratio of the collateral
    function getLTV(uint256 collateralId) public view returns (uint256) {
        return collateralLTV[collateralId];
    }

    /// @notice Calculates the maximum loan amount for a given collateral and its valuation
    /// @param collateralId The ID of the collateral
    /// @param valuation The current valuation of the collateral
    /// @return maxLoanAmount The maximum amount that can be loaned against the collateral
    function calculateMaxLoanAmount(uint256 collateralId, uint256 valuation) public view returns (uint256 maxLoanAmount) {
        uint256 ltv = getLTV(collateralId);
        maxLoanAmount = valuation * ltv / 100;
        return maxLoanAmount;
    }
}
