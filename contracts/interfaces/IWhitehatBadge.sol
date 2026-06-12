// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IWhitehatBadge
/// @notice Interface used by BountyEscrow to mint whitehat reputation badges.
interface IWhitehatBadge {
    /// @notice Mints a reputation badge for a validated finding.
    /// @param whitehat Address receiving the NFT.
    /// @param findingId Identifier of the validated finding.
    /// @param tokenURI Metadata JSON URI assigned to the NFT.
    /// @return tokenId Identifier of the minted NFT.
    function mintBadge(
        address whitehat,
        uint256 findingId,
        string calldata tokenURI
    ) external returns (uint256 tokenId);
}
