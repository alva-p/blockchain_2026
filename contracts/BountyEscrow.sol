// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IFindingRegistry.sol";
import "./interfaces/IWhitehatBadge.sol";

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
