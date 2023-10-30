// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title A contract for collateralizing NFTs for loans
/// @notice This contract allows users to deposit NFTs as collateral which can then be used for loan purposes
/// @dev This contract supports ERC721 and ERC1155 NFT standards
contract NFTCollateralContract is Ownable  (msg.sender) {
    using Counters for Counters.Counter;
    Counters.Counter private _depositIds;

    enum TokenType { ERC721, ERC1155 }

    /// @notice Holds details about the NFT deposit
    /// @dev Stores the address of the depositor, the NFT, and the token type
    struct NFTDeposit {
        address depositor;
        address nftAddress;
        uint256 tokenId;
        TokenType tokenType;
    }

    // Mapping from deposit ID to NFTDeposit
    mapping(uint256 => NFTDeposit) private _deposits;

    /// @notice Emitted when an NFT is deposited
    event Deposit(address indexed depositor, address indexed nftAddress, uint256 indexed tokenId, uint256 depositId, TokenType tokenType);

    /// @notice Emitted when an NFT is withdrawn
    event Withdraw(address indexed depositor, uint256 indexed depositId);

    /// @notice Allows users to deposit their NFTs as collateral
    /// @dev Transfers an NFT from the depositor to this contract
    /// @param nftAddress The address of the NFT contract
    /// @param tokenId The ID of the NFT
    /// @param tokenType The type of the NFT (ERC721 or ERC1155)
    /// @return depositId The unique ID of the deposit
    function depositNFT(address nftAddress, uint256 tokenId, TokenType tokenType) external returns (uint256) {
        require(nftAddress != address(0), "NFT address cannot be zero");

        _depositIds.increment();
        uint256 newDepositId = _depositIds.current();

        if (tokenType == TokenType.ERC721) {
            IERC721(nftAddress).transferFrom(msg.sender, address(this), tokenId);
        } else if (tokenType == TokenType.ERC1155) {
            IERC1155(nftAddress).safeTransferFrom(msg.sender, address(this), tokenId, 1, "");
        } else {
            revert("Invalid token type");
        }

        _deposits[newDepositId] = NFTDeposit({
            depositor: msg.sender,
            nftAddress: nftAddress,
            tokenId: tokenId,
            tokenType: tokenType
        });

        emit Deposit(msg.sender, nftAddress, tokenId, newDepositId, tokenType);

        return newDepositId;
    }

    /// @notice Allows users to withdraw their NFTs
    /// @dev Transfers the NFT from this contract back to the depositor
    /// @param depositId The unique ID of the deposit
    function withdrawNFT(uint256 depositId) external {
        NFTDeposit memory deposit = _deposits[depositId];

        require(deposit.depositor == msg.sender, "Caller is not the depositor");
        require(deposit.nftAddress != address(0), "No NFT to withdraw");

        if (deposit.tokenType == TokenType.ERC721) {
            IERC721(deposit.nftAddress).transferFrom(address(this), msg.sender, deposit.tokenId);
        } else if (deposit.tokenType == TokenType.ERC1155) {
            IERC1155(deposit.nftAddress).safeTransferFrom(address(this), msg.sender, deposit.tokenId, 1, "");
        }

        delete _deposits[depositId];

        emit Withdraw(msg.sender, depositId);
    }

    /// @notice Retrieves details of a specific NFT deposit
    /// @dev View function to get details of the NFT deposit
    /// @param depositId The unique ID of the deposit
    /// @return The address of the depositor, the NFT address, token ID, and token type
    function getCollateralDetails(uint256 depositId) external view returns (address, address, uint256, TokenType) {
        NFTDeposit memory deposit = _deposits[depositId];
        return (deposit.depositor, deposit.nftAddress, deposit.tokenId, deposit.tokenType);
    }
}
