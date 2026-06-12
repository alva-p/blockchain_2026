// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// lib/openzeppelin-contracts/contracts/utils/Context.sol

// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// contracts/interfaces/IFindingRegistry.sol

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

// lib/openzeppelin-contracts/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// contracts/FindingRegistry.sol

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
