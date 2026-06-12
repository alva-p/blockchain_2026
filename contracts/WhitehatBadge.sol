// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./interfaces/IWhitehatBadge.sol";

error ZeroAddress();
error NotMinter();
error EmptyTokenURI();
error InvalidFinding();
error BadgeAlreadyMinted();
error SoulboundToken();

/// @title WhitehatBadge
/// @notice Soulbound ERC721 reputation badge minted for whitehats with validated findings.
contract WhitehatBadge is Ownable, ERC721URIStorage, IWhitehatBadge {
    address private _minter;
    uint256 private _nextTokenId = 1;

    mapping(uint256 tokenId => uint256 findingId) private _tokenFinding;
    mapping(uint256 findingId => uint256 tokenId) private _findingToken;

    event MinterUpdated(address indexed oldMinter, address indexed newMinter);
    event BadgeMinted(address indexed whitehat, uint256 indexed tokenId, uint256 indexed findingId, string tokenURI);

    constructor() ERC721("BugBountyShield Whitehat Badge", "BBS") Ownable(msg.sender) {}

    modifier onlyMinter() {
        if (msg.sender != _minter) revert NotMinter();
        _;
    }

    /// @notice Sets the only contract allowed to mint badges.
    /// @param newMinter Address of the deployed BountyEscrow contract.
    function setMinter(address newMinter) external onlyOwner {
        if (newMinter == address(0)) revert ZeroAddress();
        address oldMinter = _minter;
        _minter = newMinter;
        emit MinterUpdated(oldMinter, newMinter);
    }

    /// @notice Returns the authorized minter contract.
    /// @return minterAddress Current authorized BountyEscrow address.
    function minter() external view returns (address minterAddress) {
        return _minter;
    }

    /// @notice Mints a soulbound reputation badge for a validated finding.
    /// @param whitehat Address receiving the NFT.
    /// @param findingId Identifier of the validated finding.
    /// @param tokenURI Metadata JSON URI assigned to the NFT.
    /// @return tokenId Identifier of the minted NFT.
    function mintBadge(
        address whitehat,
        uint256 findingId,
        string calldata tokenURI
    ) external onlyMinter returns (uint256 tokenId) {
        if (whitehat == address(0)) revert ZeroAddress();
        if (findingId == 0) revert InvalidFinding();
        if (bytes(tokenURI).length == 0) revert EmptyTokenURI();
        if (_findingToken[findingId] != 0) revert BadgeAlreadyMinted();

        tokenId = _nextTokenId;
        _nextTokenId++;

        _safeMint(whitehat, tokenId);
        _setTokenURI(tokenId, tokenURI);
        _tokenFinding[tokenId] = findingId;
        _findingToken[findingId] = tokenId;

        emit BadgeMinted(whitehat, tokenId, findingId, tokenURI);
    }

    /// @notice Returns the finding ID represented by a token.
    /// @param tokenId NFT token identifier.
    /// @return findingId Finding linked to the badge.
    function tokenFinding(uint256 tokenId) external view returns (uint256 findingId) {
        _requireOwned(tokenId);
        return _tokenFinding[tokenId];
    }

    /// @notice Returns the token ID minted for a finding.
    /// @param findingId Identifier of the finding.
    /// @return tokenId Badge token linked to the finding, or 0 if none exists.
    function findingToken(uint256 findingId) external view returns (uint256 tokenId) {
        return _findingToken[findingId];
    }

    /// @notice Blocks single-token approvals because badges are soulbound.
    /// @param to Approval target.
    /// @param tokenId Token identifier.
    function approve(address to, uint256 tokenId) public pure override(ERC721, IERC721) {
        to;
        tokenId;
        revert SoulboundToken();
    }

    /// @notice Blocks operator approvals because badges are soulbound.
    /// @param operator Operator address.
    /// @param approved Approval status.
    function setApprovalForAll(address operator, bool approved) public pure override(ERC721, IERC721) {
        operator;
        approved;
        revert SoulboundToken();
    }

    /// @notice Returns the next token ID that will be minted.
    /// @return nextId Next token ID.
    function nextTokenId() external view returns (uint256 nextId) {
        return _nextTokenId;
    }

    /// @notice Blocks token transfers after minting so badges remain soulbound.
    /// @param to Destination address.
    /// @param tokenId Token identifier.
    /// @param auth Address authorized for the update.
    /// @return previousOwner Previous token owner.
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override returns (address previousOwner) {
        previousOwner = _ownerOf(tokenId);
        if (previousOwner != address(0) && to != address(0)) revert SoulboundToken();
        return super._update(to, tokenId, auth);
    }

}
