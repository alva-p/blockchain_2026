// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IFindingRegistry.sol";

error ZeroAddress();
error NotEscrow();
error EmptySeverity();
error EmptyReportHash();
error InvalidFinding();
error FindingNotSubmitted();

/// @title FindingRegistry
/// @notice Stores the technical traceability of findings submitted through BountyEscrow.
contract FindingRegistry is Ownable, IFindingRegistry {
    address private _escrow;
    uint256 private _nextFindingId = 1;

    mapping(uint256 findingId => Finding finding) private _findings;
    mapping(uint256 bountyId => uint256[] findingIds) private _findingsByBounty;
    mapping(address researcher => uint256[] findingIds) private _findingsByResearcher;

    event EscrowUpdated(address indexed oldEscrow, address indexed newEscrow);
    event FindingRegistered(
        uint256 indexed findingId,
        uint256 indexed bountyId,
        address indexed researcher,
        bytes32 reportHash,
        string severity
    );
    event FindingValidated(uint256 indexed findingId);
    event FindingRejected(uint256 indexed findingId);

    constructor() Ownable(msg.sender) {}

    modifier onlyEscrow() {
        if (msg.sender != _escrow) revert NotEscrow();
        _;
    }

    /// @notice Sets the only BountyEscrow contract allowed to mutate findings.
    /// @param newEscrow Address of the deployed BountyEscrow contract.
    function setEscrow(address newEscrow) external onlyOwner {
        if (newEscrow == address(0)) revert ZeroAddress();
        address oldEscrow = _escrow;
        _escrow = newEscrow;
        emit EscrowUpdated(oldEscrow, newEscrow);
    }

    /// @notice Returns the authorized escrow contract.
    /// @return escrowAddress Current authorized BountyEscrow address.
    function escrow() external view returns (address escrowAddress) {
        return _escrow;
    }

    /// @notice Registers a new finding as submitted.
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
    ) external onlyEscrow returns (uint256 findingId) {
        if (researcher == address(0)) revert ZeroAddress();
        if (reportHash == bytes32(0)) revert EmptyReportHash();
        if (bytes(severity).length == 0) revert EmptySeverity();

        findingId = _nextFindingId;
        _nextFindingId++;

        _findings[findingId] = Finding({
            id: findingId,
            bountyId: bountyId,
            researcher: researcher,
            reportHash: reportHash,
            severity: severity,
            status: FindingStatus.Submitted,
            createdAt: block.timestamp
        });

        _findingsByBounty[bountyId].push(findingId);
        _findingsByResearcher[researcher].push(findingId);

        emit FindingRegistered(findingId, bountyId, researcher, reportHash, severity);
    }

    /// @notice Marks a submitted finding as validated.
    /// @param findingId Identifier of the finding to validate.
    function validateFinding(uint256 findingId) external onlyEscrow {
        Finding storage finding = _findings[findingId];
        if (finding.id == 0) revert InvalidFinding();
        if (finding.status != FindingStatus.Submitted) revert FindingNotSubmitted();

        finding.status = FindingStatus.Validated;
        emit FindingValidated(findingId);
    }

    /// @notice Marks a submitted finding as rejected.
    /// @param findingId Identifier of the finding to reject.
    function rejectFinding(uint256 findingId) external onlyEscrow {
        Finding storage finding = _findings[findingId];
        if (finding.id == 0) revert InvalidFinding();
        if (finding.status != FindingStatus.Submitted) revert FindingNotSubmitted();

        finding.status = FindingStatus.Rejected;
        emit FindingRejected(findingId);
    }

    /// @notice Returns a finding by ID.
    /// @param findingId Identifier of the finding.
    /// @return finding Full finding data.
    function getFinding(uint256 findingId) external view returns (Finding memory finding) {
        finding = _findings[findingId];
        if (finding.id == 0) revert InvalidFinding();
    }

    /// @notice Returns all finding IDs linked to a bounty.
    /// @param bountyId Identifier of the bounty.
    /// @return findingIds Array of finding IDs.
    function getFindingsByBounty(uint256 bountyId) external view returns (uint256[] memory findingIds) {
        return _findingsByBounty[bountyId];
    }

    /// @notice Returns all finding IDs submitted by a researcher.
    /// @param researcher Address of the whitehat researcher.
    /// @return findingIds Array of finding IDs.
    function getFindingsByResearcher(address researcher) external view returns (uint256[] memory findingIds) {
        return _findingsByResearcher[researcher];
    }

    /// @notice Returns the next finding ID that will be assigned.
    /// @return nextId Next finding ID.
    function nextFindingId() external view returns (uint256 nextId) {
        return _nextFindingId;
    }
}
