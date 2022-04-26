// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC721A.sol";

contract Testing is ERC721A, Ownable {
    using SafeMath for uint256;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    bool public paused = true;
    bool public onlySpecial = false;
    bool public onlyWhitelisted = false;
    bool public openSpecial = false;
    bool public openPresale = false;
    bool public openPublic = false;
    bool public revealed = false;

    uint256 public maxSupplySpecial = 100;
    uint256 public maxSupplyPresale = 1000;
    uint256 public maxSupply = 5000;
    uint256 public maxMintAmount = 100;
    uint256 public costSpecial = 0.001 ether;
    uint256 public costPreSale = 0.0015 ether;
    uint256 public costPublic = 0.002 ether;
    uint256 public reward = 0.001 ether;

    address[] public whitelistedAddresses;
    address payable[] public epicsAddresses;

    constructor(uint256 maxBatchSize_, uint256 collectionSize_ ) 
        ERC721A("TEST", "TT", maxBatchSize_, collectionSize_) {
        setHiddenMetadataUri("ipfs://url/notRevealed.json");
    }

    function mint(address _owner, uint256 _mintAmount) external payable {
        require(!paused, "The sale is paused");
        address wallet = _owner;
        uint256 supplyNow = totalSupply();
        uint256 cost = costPublic;
        uint256 ownerTokenCount = balanceOf(msg.sender);

        if (msg.sender != owner()) {
            if (openPublic) {
                require(_mintAmount <= maxMintAmount && ownerTokenCount + _mintAmount <= maxMintAmount, "You cannot own more than 5 NFTs");
            }
            else if (onlyWhitelisted) {
                require(isWhitelisted(msg.sender), "You are not in the whitelist, wait for the public sale");
                require(supplyNow + _mintAmount <= maxSupplyPresale, "Cannot mint more than 1000 NTFs in the private sale");
                require(_mintAmount <= maxMintAmount && ownerTokenCount + _mintAmount <= maxMintAmount, "You cannot own more than 3 NFTs");
                cost = costPreSale;
            }
            else if (onlySpecial) {
                require(isWhitelisted(msg.sender), "You are not in the whitelist, wait for the public sale");
                require(supplyNow + _mintAmount <= maxSupplySpecial, "Cannot mint more than 100 NTFs in the special sale");
                require(_mintAmount <= maxMintAmount && ownerTokenCount + _mintAmount <= maxMintAmount, "You cannot own more than 2 NFTs");
                cost = costSpecial;
            }
        }
        require(msg.value >= cost * _mintAmount, "The value must cover the total number of mints");
        _safeMint(msg.sender, _mintAmount);
    }

    function walletOfOwner(address _owner)
        public view returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
        address currentTokenOwner = ownerOf(currentTokenId);

        if (currentTokenOwner == _owner) {
            ownedTokenIds[ownedTokenIndex] = currentTokenId;
            ownedTokenIndex++;
        }
        currentTokenId++;
        }
        return ownedTokenIds;
    }

    function tokenURI(uint256 _tokenId)
        public view virtual override returns (string memory)
    {
        require(
        _exists(_tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId, uriSuffix))
            : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    // USEFUL FUNCTIONS ONLYOWNER

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setOpenSpecial(bool _state) public onlyOwner {
        openSpecial = _state;
    }

    function setOpenPresale(bool _state) public onlyOwner {
        openPresale = _state;
    }

    function setOpenPublic(bool _state) public onlyOwner {
        openPublic = _state;
    }

    function setCost(uint256 option, uint256 _newCost) public onlyOwner() {
        if (option == 1){
            costSpecial = _newCost;
        }
        else if (option == 2){
            costPreSale = _newCost;
        }
        else {
            costPublic = _newCost;
        }
        
    }

    function setReward(uint256 _newCost) public onlyOwner() {
        reward = _newCost;
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
        maxMintAmount = _newMaxMintAmount;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setWhitelistAddresses(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    function setEpicsAddresses(address payable[] calldata _users) public onlyOwner {
        delete epicsAddresses;
        epicsAddresses = _users;
    }

    function withdraw(uint256 amount) public onlyOwner {
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success);
    }

    function withdrawAll() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success);
    }

    function sendRewardToEpics() public payable onlyOwner {
        for(uint256 i = 0; i < epicsAddresses.length; i++) {
            epicsAddresses[i].transfer(reward);
        }
    }

    // USEFUL FUNCTIONS PUBLIC

    function isWhitelisted(address _user) public view returns (bool) {
        for(uint256 i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function totalSupplyMax() public view returns (uint256) {
        return maxSupply;
    }

}