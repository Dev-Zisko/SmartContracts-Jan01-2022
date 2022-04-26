// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SmartContract is ERC721Enumerable, Ownable {
    using Strings for uint256;

    // Variables
    string baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;
    bool public paused = true;
    bool public openPublic = false;
    bool public revealed = false;

    uint256 public rewardDiamond = 0.0003 ether;
    uint256 public rewardGold= 0.0001 ether;

    uint256 public maxSupplyPresale = 1000;
    uint256 public maxSupply = 5000;

    uint256 public maxMintAmount = 5;

    uint256 public costPreSale = 0.0003 ether;
    uint256 public costPublic = 0.0005 ether;

    bool public onlyWhitelisted = true;
    address[] public whitelistedAddresses;
    address payable[] public diamondWinners;
    address payable[] public goldWinners;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    // Internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(address _owner, uint256 _mintAmount) public payable {
        require(!paused, "The sale is paused");
        address wallet = _owner;
        uint256 supply = totalSupply();
        uint256 cost = costPublic;
        uint256 ownerTokenCount = balanceOf(msg.sender);

        require(ownerTokenCount + _mintAmount <= maxMintAmount, "You cannot own more than 5 NFTs");
        require(_mintAmount > 0, "You must mint at least 1 NFTs");
        require(_mintAmount <= maxMintAmount, "You cannot own more than 5 NFTs");
        require(supply + _mintAmount <= maxSupply, "Cannot mint more than 5000 NTFs");

        if (msg.sender != owner()) {
            if (onlyWhitelisted) {
                require(isWhitelisted(msg.sender), "You are not in the whitelist, wait for the public sale");
                require(supply + _mintAmount <= maxSupplyPresale, "Cannot mint more than 1000 NTFs in the private sale");
                cost = costPreSale;
            } else {
                require(openPublic, "Public sale is not enabled yet");
            }
        }

        require(msg.value >= cost * _mintAmount, "The value must cover the total number of mints");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(wallet, supply + i);
        }
    }

    function isWhitelisted(address _user) public view returns (bool) {
        for(uint256 i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function isDiamondWinner(address _user) public view returns (bool) {
        for(uint256 i = 0; i < diamondWinners.length; i++) {
            if (diamondWinners[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function isGoldWinner(address _user) public view returns (bool) {
        for(uint256 i = 0; i < goldWinners.length; i++) {
            if (goldWinners[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
        _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        
        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    //only owner
    function reveal() public onlyOwner() {
        revealed = true;
    }

    function setCostPreSale(uint256 _newCost) public onlyOwner() {
        costPreSale = _newCost;
    }
    
    function setCostPublic(uint256 _newCost) public onlyOwner() {
        costPublic = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
        maxMintAmount = _newmaxMintAmount;
    }
    
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setOpenPublic(bool _state) public onlyOwner {
        openPublic = _state;
    }

    function whitelistUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    function setDiamondWinners(address payable[] calldata _users) public onlyOwner {
        delete diamondWinners;
        diamondWinners = _users;
    }

    function setGoldWinners(address payable[] calldata _users) public onlyOwner {
        delete goldWinners;
        goldWinners = _users;
    }

    function sendRewardToDiamondWinners() public payable onlyOwner {
        for(uint256 i = 0; i < diamondWinners.length; i++) {
            diamondWinners[i].transfer(rewardDiamond);
        }
    }

    function sendRewardToGoldWinners() public payable onlyOwner {
        for(uint256 i = 0; i < goldWinners.length; i++) {
            goldWinners[i].transfer(rewardGold);
        }
    }

    function sendRemaining(address payable recipient) public payable onlyOwner {
        recipient.transfer(address(this).balance);
    }

    function totalBalance() public view returns (uint256 amount) {
        return address(this).balance;
    }
    
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

}