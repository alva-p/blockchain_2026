// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IFindingRegistry
/// @notice Interface used by BountyEscrow to interact with the finding registry.
interface IFindingRegistry {
    enum FindingStatus {
        Submitted,
        Validated,
        Rejected
    }

    struct Finding {
        uint256 id;
        uint256 bountyId;
        address researcher;
        bytes32 reportHash;
        string severity;
        FindingStatus status;
        uint256 createdAt;
    }

    /// @notice Registers a new finding.
    /// @param bountyId Identifier of the bounty associated with the finding.
    /// @param researcher Address of the whitehat researcher.
    /// @param reportHash Hash of the off-chain report.
    /// @param severity Human-readable severity value.
    /// @return findingId Identifier assigned to the finding.
    function registerFinding(
        uint256 bountyId,
        address researcher,
        bytes32 reportHash,
        string calldata severity
    ) external returns (uint256 findingId);

    /// @notice Marks a submitted finding as validated.
    /// @param findingId Identifier of the finding to validate.
    function validateFinding(uint256 findingId) external;

    /// @notice Marks a submitted finding as rejected.
    /// @param findingId Identifier of the finding to reject.
    function rejectFinding(uint256 findingId) external;

    /// @notice Returns a finding by ID.
    /// @param findingId Identifier of the finding.
    /// @return finding Full finding data.
    function getFinding(uint256 findingId) external view returns (Finding memory finding);
}
