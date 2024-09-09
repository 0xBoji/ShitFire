// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ShitNFT
 * @dev This contract implements an ERC721 token with additional features like URI storage and controlled burning.
 *      It is designed to represent Shit NFTs. Burning is only allowed through specific functions.
 */
contract ShitNFT is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    uint256 private _nextTokenId;
    mapping(address => uint256[]) private _ownedTokens;
    address[] private _minters;
    mapping(address => bool) private _isMinter;
    IERC20 public immutable airdropToken;
    uint256 public immutable tokenPerNFT;
    IERC20 public immutable rewardToken;
    uint256 public immutable rewardPerNFT;

    struct MintInfo {
        address minter;
        uint256 tokenId;
    }
    
    MintInfo[] private _mintHistory;
    mapping(address => bool) private _hasMinted;
    mapping(address => uint256) private _minterTokenCount;
    mapping(uint256 => bool) private _burnedTokens;

    constructor(
        address _airdropToken,
        uint256 _tokenPerNFT,
        address _rewardToken,
        uint256 _rewardPerNFT
    ) ERC721("DragonShitNFT", "DragonShitNFT") Ownable(msg.sender) {
        require(_airdropToken != address(0), "Invalid airdrop token address");
        require(_tokenPerNFT > 0, "Invalid token amount per NFT");
        require(_rewardToken != address(0), "Invalid reward token address");
        require(_rewardPerNFT > 0, "Invalid reward amount per NFT");
        airdropToken = IERC20(_airdropToken);
        tokenPerNFT = _tokenPerNFT;
        rewardToken = IERC20(_rewardToken);
        rewardPerNFT = _rewardPerNFT;
    }

    /**
     * @dev Mints a new token with the given URI and assigns it to the specified address.
     * @param to The address to which the token will be minted.
     * @param uri The URI for the token metadata.
     */
    function safeMint(address to, string memory uri) public {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        _ownedTokens[to].push(tokenId);

        _mintHistory.push(MintInfo(msg.sender, tokenId));
        if (!_hasMinted[msg.sender]) {
            _hasMinted[msg.sender] = true;
            _minters.push(msg.sender);
        }
        _minterTokenCount[msg.sender]++;
    }

    /**
     * @dev Overrides the transferFrom function to prevent token transfers.
     * @param from The address from which the token is transferred.
     * @param to The address to which the token is transferred.
     * @param tokenId The ID of the token being transferred.
     */
    function transferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721, IERC721)
        virtual
    {
        require(from == address(0), "Err: token transfer is BLOCKED");
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev Retrieves the URI for the specified token.
     * @param tokenId The ID of the token for which the URI will be retrieved.
     * @return string The URI for the token metadata.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Checks whether the contract supports the given interface.
     * @param interfaceId The ID of the interface.
     * @return bool True if the contract supports the given interface, false otherwise.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Retrieves all Shit NFTs owned by a specific address.
     * @param owner The address whose Shit NFTs will be retrieved.
     * @return uint256[] An array of token IDs owned by the specified address.
     */
    function getShitNFTs(address owner) public view returns (uint256[] memory) {
        require(owner != address(0), "Invalid address");
        return _ownedTokens[owner];
    }

    /**
     * @dev Retrieves the mint history.
     * @return MintInfo[] An array of MintInfo structs containing minter addresses and token IDs.
     */
    function getMintHistory() public view returns (MintInfo[] memory) {
        uint256 activeTokenCount = 0;
        for (uint256 i = 0; i < _mintHistory.length; i++) {
            if (!_burnedTokens[_mintHistory[i].tokenId]) {
                activeTokenCount++;
            }
        }

        MintInfo[] memory activeMintHistory = new MintInfo[](activeTokenCount);
        uint256 index = 0;
        for (uint256 i = 0; i < _mintHistory.length; i++) {
            if (!_burnedTokens[_mintHistory[i].tokenId]) {
                activeMintHistory[index] = _mintHistory[i];
                index++;
            }
        }

        return activeMintHistory;
    }

    /**
     * @dev Retrieves the list of addresses that have minted ShitNFTs.
     * @return address[] An array of addresses that have minted ShitNFTs.
     */
    function getMinters() public view returns (address[] memory) {
        return _minters;
    }

    /**
     * @dev Airdrops tokens to the caller based on the number of Shit NFTs they own.
     */
    function airdropTokens() external {
        uint256[] memory ownedNFTs = _ownedTokens[msg.sender];
        require(ownedNFTs.length > 0, "You don't own any Shit NFTs");

        uint256 totalAirdropAmount = 0;
        uint256 totalRewardAmount = ownedNFTs.length * rewardPerNFT;
        address[] memory eligibleMinters = new address[](ownedNFTs.length);
        uint256 eligibleMintersCount = 0;

        for (uint256 i = 0; i < ownedNFTs.length; i++) {
            address minter = _mintHistory[ownedNFTs[i]].minter;
            bool isNewMinter = true;
            for (uint256 j = 0; j < eligibleMintersCount; j++) {
                if (eligibleMinters[j] == minter) {
                    isNewMinter = false;
                    break;
                }
            }
            if (isNewMinter) {
                eligibleMinters[eligibleMintersCount] = minter;
                eligibleMintersCount++;
                totalAirdropAmount += tokenPerNFT;
            }
        }

        require(airdropToken.balanceOf(msg.sender) >= totalAirdropAmount, "Err: Insufficient airdrop token balance");
        require(rewardToken.balanceOf(address(this)) >= totalRewardAmount, "Err: Insufficient reward token balance in contract");

        for (uint256 i = 0; i < eligibleMintersCount; i++) {
            require(airdropToken.transferFrom(msg.sender, eligibleMinters[i], tokenPerNFT), "Err: Airdrop failed");
        }

        require(rewardToken.transfer(msg.sender, totalRewardAmount), "Err: Reward transfer failed");

        // Burn all Shit NFT of caller and update minter information
        _burnAllShitNFTs(msg.sender);
    }

    /**
     * @dev Internal function to burn all Shit NFTs owned by the caller.
     * @param owner The address whose Shit NFTs will be burned.
     */
    function _burnAllShitNFTs(address owner) internal {
        uint256[] memory tokenIds = _ownedTokens[owner];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            address minter = _mintHistory[tokenId].minter;
            
            super._burn(tokenId);
            _burnedTokens[tokenId] = true;
            
            _minterTokenCount[minter]--;
            if (_minterTokenCount[minter] == 0) {
                _removeMinter(minter);
            }
        }
        delete _ownedTokens[owner];
    }

    function _removeMinter(address minter) internal {
        for (uint256 i = 0; i < _minters.length; i++) {
            if (_minters[i] == minter) {
                _minters[i] = _minters[_minters.length - 1];
                _minters.pop();
                break;
            }
        }
        delete _hasMinted[minter];
    }

    /**
     * @dev Prevents any external burn attempts by overriding the `burn` function from `ERC721Burnable`.
     * This function does nothing and will revert if called.
     */
    function burn(uint256 /*tokenId*/) public pure override(ERC721Burnable) {
        revert("Err: Direct burn not allowed");
    }

    function getContractRewardBalance() public view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }

    function withdrawExcessRewardTokens(uint256 amount) external onlyOwner {
        uint256 contractBalance = rewardToken.balanceOf(address(this));
        require(contractBalance >= amount, "Err: Insufficient reward token balance in contract");
        require(rewardToken.transfer(msg.sender, amount), "Err: Withdrawal failed");
    }
}