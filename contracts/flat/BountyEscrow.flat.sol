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

// contracts/interfaces/IWhitehatBadge.sol

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

// lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol

// OpenZeppelin Contracts (last updated v5.1.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC-1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     // Define the slot. Alternatively, use the SlotDerivation library to derive the slot.
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(newImplementation.code.length > 0);
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * TIP: Consider using this library along with {SlotDerivation}.
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct Int256Slot {
        int256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `Int256Slot` with member `value` located at `slot`.
     */
    function getInt256Slot(bytes32 slot) internal pure returns (Int256Slot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        assembly ("memory-safe") {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns a `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        assembly ("memory-safe") {
            r.slot := store.slot
        }
    }
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

// lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol

// OpenZeppelin Contracts (last updated v5.5.0) (utils/ReentrancyGuard.sol)

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If EIP-1153 (transient storage) is available on the chain you're deploying at,
 * consider using {ReentrancyGuardTransient} instead.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * IMPORTANT: Deprecated. This storage-based reentrancy guard will be removed and replaced
 * by the {ReentrancyGuardTransient} variant in v6.0.
 *
 * @custom:stateless
 */
abstract contract ReentrancyGuard {
    using StorageSlot for bytes32;

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ReentrancyGuard")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant REENTRANCY_GUARD_STORAGE =
        0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00;

    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _reentrancyGuardStorageSlot().getUint256Slot().value = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    /**
     * @dev A `view` only version of {nonReentrant}. Use to block view functions
     * from being called, preventing reading from inconsistent contract state.
     *
     * CAUTION: This is a "view" modifier and does not change the reentrancy
     * status. Use it only on view functions. For payable or non-payable functions,
     * use the standard {nonReentrant} modifier instead.
     */
    modifier nonReentrantView() {
        _nonReentrantBeforeView();
        _;
    }

    function _nonReentrantBeforeView() private view {
        if (_reentrancyGuardEntered()) {
            revert ReentrancyGuardReentrantCall();
        }
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        _nonReentrantBeforeView();

        // Any calls to nonReentrant after this point will fail
        _reentrancyGuardStorageSlot().getUint256Slot().value = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _reentrancyGuardStorageSlot().getUint256Slot().value = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _reentrancyGuardStorageSlot().getUint256Slot().value == ENTERED;
    }

    function _reentrancyGuardStorageSlot() internal pure virtual returns (bytes32) {
        return REENTRANCY_GUARD_STORAGE;
    }
}

// contracts/BountyEscrow.sol

error ZeroAddress();
error EmptyTitle();
error EmptyDescription();
error EmptyReportHash();
error EmptySeverity();
error EmptyTokenURI();
error NoEtherSent();
error InvalidBounty();
error BountyNotActive();
error BountyNotCancelled();
error NotBountyCompany();
error NotReviewer();
error FindingNotSubmitted();
error FindingBountyInactive();
error InsufficientFunds();
error NothingToWithdraw();
error EthTransferFailed();

/// @title BountyEscrow
/// @notice Escrow contract that locks bounty ETH, coordinates finding review and pays validated whitehats.
contract BountyEscrow is Ownable, ReentrancyGuard {
    struct Bounty {
        uint256 id;
        address company;
        string title;
        string description;
        uint256 depositedAmount;
        uint256 remainingFunds;
        bool active;
        bool cancelled;
        uint256 createdAt;
    }

    IFindingRegistry private immutable _findingRegistry;
    IWhitehatBadge private immutable _whitehatBadge;

    uint256 private _nextBountyId = 1;
    address private _reviewer;

    mapping(uint256 bountyId => Bounty bounty) private _bounties;

    event ReviewerUpdated(address indexed oldReviewer, address indexed newReviewer);
    event BountyCreated(
        uint256 indexed bountyId,
        address indexed company,
        uint256 amount,
        string title,
        string description
    );
    event FindingSubmitted(
        uint256 indexed bountyId,
        uint256 indexed findingId,
        address indexed researcher,
        bytes32 reportHash,
        string severity
    );
    event FindingApproved(
        uint256 indexed findingId,
        uint256 indexed bountyId,
        address indexed whitehat,
        uint256 rewardAmount,
        uint256 badgeTokenId,
        string tokenURI
    );
    event FindingRejected(uint256 indexed findingId, uint256 indexed bountyId, address indexed reviewer);
    event BountyCancelled(uint256 indexed bountyId, address indexed company);
    event RemainingFundsWithdrawn(uint256 indexed bountyId, address indexed company, uint256 amount);

    constructor(address findingRegistryAddress, address whitehatBadgeAddress) Ownable(msg.sender) {
        if (findingRegistryAddress == address(0) || whitehatBadgeAddress == address(0)) revert ZeroAddress();
        _findingRegistry = IFindingRegistry(findingRegistryAddress);
        _whitehatBadge = IWhitehatBadge(whitehatBadgeAddress);
        _reviewer = msg.sender;
        emit ReviewerUpdated(address(0), msg.sender);
    }

    modifier onlyReviewer() {
        if (msg.sender != owner() && msg.sender != _reviewer) revert NotReviewer();
        _;
    }

    /// @notice Sets the reviewer allowed to approve and reject findings.
    /// @param newReviewer Address of the new reviewer.
    function setReviewer(address newReviewer) external onlyOwner {
        if (newReviewer == address(0)) revert ZeroAddress();
        address oldReviewer = _reviewer;
        _reviewer = newReviewer;
        emit ReviewerUpdated(oldReviewer, newReviewer);
    }

    /// @notice Creates a new bounty and locks the sent ETH as reward funds.
    /// @param title Short bounty title.
    /// @param description Human-readable bounty description.
    /// @return bountyId Identifier assigned to the bounty.
    function createBounty(
        string calldata title,
        string calldata description
    ) external payable nonReentrant returns (uint256 bountyId) {
        if (msg.value == 0) revert NoEtherSent();
        if (bytes(title).length == 0) revert EmptyTitle();
        if (bytes(description).length == 0) revert EmptyDescription();

        bountyId = _nextBountyId;
        _nextBountyId++;

        _bounties[bountyId] = Bounty({
            id: bountyId,
            company: msg.sender,
            title: title,
            description: description,
            depositedAmount: msg.value,
            remainingFunds: msg.value,
            active: true,
            cancelled: false,
            createdAt: block.timestamp
        });

        emit BountyCreated(bountyId, msg.sender, msg.value, title, description);
    }

    /// @notice Submits a finding for an active bounty through FindingRegistry.
    /// @param bountyId Identifier of the bounty.
    /// @param reportHash Hash of the off-chain report.
    /// @param severity Human-readable severity value such as Low, Medium, High or Critical.
    /// @return findingId Identifier assigned by FindingRegistry.
    function submitFinding(
        uint256 bountyId,
        bytes32 reportHash,
        string calldata severity
    ) external returns (uint256 findingId) {
        Bounty storage bounty = _bounties[bountyId];
        if (bounty.id == 0) revert InvalidBounty();
        if (!bounty.active || bounty.cancelled) revert BountyNotActive();
        if (reportHash == bytes32(0)) revert EmptyReportHash();
        if (bytes(severity).length == 0) revert EmptySeverity();

        findingId = _findingRegistry.registerFinding(bountyId, msg.sender, reportHash, severity);
        emit FindingSubmitted(bountyId, findingId, msg.sender, reportHash, severity);
    }

    /// @notice Approves a finding, validates it, mints a badge and pays ETH to the whitehat.
    /// @param findingId Identifier of the submitted finding.
    /// @param rewardAmount Reward amount in wei.
    /// @param tokenURI Metadata JSON URI for the reputation NFT.
    function approveFinding(
        uint256 findingId,
        uint256 rewardAmount,
        string calldata tokenURI
    ) external onlyReviewer nonReentrant {
        if (rewardAmount == 0) revert NoEtherSent();
        if (bytes(tokenURI).length == 0) revert EmptyTokenURI();

        IFindingRegistry.Finding memory finding = _findingRegistry.getFinding(findingId);
        if (finding.status != IFindingRegistry.FindingStatus.Submitted) revert FindingNotSubmitted();

        Bounty storage bounty = _bounties[finding.bountyId];
        if (bounty.id == 0) revert InvalidBounty();
        if (!bounty.active || bounty.cancelled) revert FindingBountyInactive();
        if (rewardAmount > bounty.remainingFunds) revert InsufficientFunds();

        bounty.remainingFunds -= rewardAmount;

        _findingRegistry.validateFinding(findingId);
        uint256 badgeTokenId = _whitehatBadge.mintBadge(finding.researcher, findingId, tokenURI);

        (bool paid, ) = payable(finding.researcher).call{value: rewardAmount}("");
        if (!paid) revert EthTransferFailed();

        emit FindingApproved(findingId, finding.bountyId, finding.researcher, rewardAmount, badgeTokenId, tokenURI);
    }

    /// @notice Rejects a submitted finding after off-chain review.
    /// @param findingId Identifier of the submitted finding.
    function rejectFinding(uint256 findingId) external onlyReviewer {
        IFindingRegistry.Finding memory finding = _findingRegistry.getFinding(findingId);
        if (finding.status != IFindingRegistry.FindingStatus.Submitted) revert FindingNotSubmitted();

        _findingRegistry.rejectFinding(findingId);
        emit FindingRejected(findingId, finding.bountyId, msg.sender);
    }

    /// @notice Cancels an active bounty so the company can withdraw remaining funds.
    /// @param bountyId Identifier of the bounty.
    function cancelBounty(uint256 bountyId) external {
        Bounty storage bounty = _bounties[bountyId];
        if (bounty.id == 0) revert InvalidBounty();
        if (msg.sender != bounty.company && msg.sender != owner()) revert NotBountyCompany();
        if (!bounty.active || bounty.cancelled) revert BountyNotActive();

        bounty.active = false;
        bounty.cancelled = true;

        emit BountyCancelled(bountyId, bounty.company);
    }

    /// @notice Withdraws remaining funds from a cancelled bounty.
    /// @param bountyId Identifier of the bounty.
    function withdrawRemainingFunds(uint256 bountyId) external nonReentrant {
        Bounty storage bounty = _bounties[bountyId];
        if (bounty.id == 0) revert InvalidBounty();
        if (msg.sender != bounty.company) revert NotBountyCompany();
        if (!bounty.cancelled) revert BountyNotCancelled();

        uint256 amount = bounty.remainingFunds;
        if (amount == 0) revert NothingToWithdraw();

        bounty.remainingFunds = 0;

        (bool paid, ) = payable(bounty.company).call{value: amount}("");
        if (!paid) revert EthTransferFailed();

        emit RemainingFundsWithdrawn(bountyId, bounty.company, amount);
    }

    /// @notice Returns the full bounty data.
    /// @param bountyId Identifier of the bounty.
    /// @return bounty Full bounty data.
    function getBounty(uint256 bountyId) external view returns (Bounty memory bounty) {
        bounty = _bounties[bountyId];
        if (bounty.id == 0) revert InvalidBounty();
    }

    /// @notice Returns the remaining funds available in a bounty.
    /// @param bountyId Identifier of the bounty.
    /// @return remainingFunds Remaining ETH in wei.
    function getRemainingFunds(uint256 bountyId) external view returns (uint256 remainingFunds) {
        Bounty storage bounty = _bounties[bountyId];
        if (bounty.id == 0) revert InvalidBounty();
        return bounty.remainingFunds;
    }

    /// @notice Returns the configured FindingRegistry address.
    /// @return registryAddress FindingRegistry contract address.
    function findingRegistry() external view returns (address registryAddress) {
        return address(_findingRegistry);
    }

    /// @notice Returns the configured WhitehatBadge address.
    /// @return badgeAddress WhitehatBadge contract address.
    function whitehatBadge() external view returns (address badgeAddress) {
        return address(_whitehatBadge);
    }

    /// @notice Returns the current reviewer address.
    /// @return reviewerAddress Reviewer address.
    function reviewer() external view returns (address reviewerAddress) {
        return _reviewer;
    }

    /// @notice Returns the next bounty ID that will be assigned.
    /// @return nextId Next bounty ID.
    function nextBountyId() external view returns (uint256 nextId) {
        return _nextBountyId;
    }
}
