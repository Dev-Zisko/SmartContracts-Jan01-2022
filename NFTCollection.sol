// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTCollection is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;

  bool public openAdmin = true;
  bool public openSpecial = false;
  bool public openPresale = false;
  bool public openPublic = false;
  bool public revealed = false;

  uint256 public maxSupplyAdmin = 10;
  uint256 public maxSupplySpecial = 200;
  uint256 public maxSupplyPresale = 1200;
  uint256 public maxSupplyPublic = 5000;
  uint256 public maxSupply = 5000;

  uint256 public maxMintAmountAdmin = 10;
  uint256 public maxMintAmountSpecial = 3;
  uint256 public maxMintAmountPresale = 2;
  uint256 public maxMintAmountPublic = 5;

  uint256 public costAdmin = 0.0001 ether;
  uint256 public costSpecial = 0.08 ether;
  uint256 public costPresale = 0.11 ether;
  uint256 public costPublic = 0.15 ether;

  uint256 public reward = 1.4 ether;
  
  mapping(address => bool) whitelistedAdmin;
  mapping(address => bool) whitelistedSpecial;
  mapping(address => bool) whitelistedPresale;

  address payable[] public winnersAddresses;

  constructor() ERC721("NFTCollection", "NFTC") {
    setHiddenMetadataUri("ipfs://url/hidden.json");
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0, "You must mint at least 1 NFT");
    require(supply.current() + _mintAmount <= maxSupplyPublic, "You can not mint more than maxSupplyPublic NTFs");
    _;
  }

  function mintAdmin(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(openAdmin, "No active sale yet");
    require(whitelistedAdmin[msg.sender], "You are not in the admin whitelist, wait for the public sale");
    require(supply.current() + _mintAmount <= maxSupplyAdmin, "You can not mint more than maxSupplyAdmin NTFs in the admin sale");
    require(balanceOf(msg.sender) + _mintAmount <= maxMintAmountAdmin, "You can not own more than maxMintAmountAdmin NFTs");

    require(msg.value >= costAdmin * _mintAmount, "The value must cover the total number of mints");

    _mintLoop(msg.sender, _mintAmount);
  }

  function mintSpecial(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(openSpecial, "No active sale yet");
    require(whitelistedSpecial[msg.sender], "You are not in the special whitelist, wait for the public sale");
    require(supply.current() + _mintAmount <= maxSupplySpecial, "You can not mint more than maxSupplySpecial NTFs in the special sale");
    require(balanceOf(msg.sender) + _mintAmount <= maxMintAmountSpecial, "You can not own more than maxMintAmountSpecial NFTs");

    require(msg.value >= costSpecial * _mintAmount, "The value must cover the total number of mints");

    _mintLoop(msg.sender, _mintAmount);
  }

  function mintPresale(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(openPresale, "No active sale yet");
    require(whitelistedPresale[msg.sender], "You are not in the presale whitelist, wait for the public sale");
    require(supply.current() + _mintAmount <= maxSupplyPresale, "You can not mint more than maxSupplyPresale NTFs in the private sale");
    require(balanceOf(msg.sender) + _mintAmount <= maxMintAmountPresale, "You can not own more than maxMintAmountPresale NFTs");

    require(msg.value >= costPresale * _mintAmount, "The value must cover the total number of mints");

    _mintLoop(msg.sender, _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(openPublic, "No active sale yet");

    require(balanceOf(msg.sender) + _mintAmount <= maxMintAmountPublic, "You can not own more than maxMintAmountPublic NFTs");
    
    require(msg.value >= costPublic * _mintAmount, "The value must cover the total number of mints");

    _mintLoop(msg.sender, _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(_mintAmount > 0, "You must mint at least 1 NFT");
    require(supply.current() + _mintAmount <= maxSupply, "You can not mint more than maxSupply NTFs");
    _mintLoop(_receiver, _mintAmount);
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
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
    public
    view
    virtual
    override
    returns (string memory)
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
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  // USEFUL FUNCTIONS ONLYOWNER

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setOpenAdmin(bool _state) public onlyOwner {
    openAdmin = _state;
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

  function setCostAdmin(uint256 _newCost) public onlyOwner() {
    costAdmin = _newCost;
  }

  function setCostSpecial(uint256 _newCost) public onlyOwner() {
    costSpecial = _newCost;
  }

  function setCostPresale(uint256 _newCost) public onlyOwner() {
    costPresale = _newCost;
  }

  function setCostPublic(uint256 _newCost) public onlyOwner() {
    costPublic = _newCost;
  }

  function setReward(uint256 _newReward) public onlyOwner() {
    reward = _newReward;
  }

  function setMaxSupplyAdmin(uint256 _newMaxSupply) public onlyOwner {
    maxSupplyAdmin = _newMaxSupply;
  }

  function setMaxSupplySpecial(uint256 _newMaxSupply) public onlyOwner {
    maxSupplySpecial = _newMaxSupply;
  }

  function setMaxSupplyPresale(uint256 _newMaxSupply) public onlyOwner {
    maxSupplyPresale = _newMaxSupply;
  }

  function setMaxSupplyPublic(uint256 _newMaxSupply) public onlyOwner {
    maxSupplyPublic = _newMaxSupply;
  }

  function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
    maxSupply = _newMaxSupply;
  }

  function setMaxMintAmountAdmin(uint256 _newMaxMintAmount) public onlyOwner {
    maxMintAmountAdmin = _newMaxMintAmount;
  }

  function setMaxMintAmountSpecial(uint256 _newMaxMintAmount) public onlyOwner {
    maxMintAmountSpecial = _newMaxMintAmount;
  }

  function setMaxMintAmountPresale(uint256 _newMaxMintAmount) public onlyOwner {
    maxMintAmountPresale = _newMaxMintAmount;
  }

  function setMaxMintAmountPublic(uint256 _newMaxMintAmount) public onlyOwner {
    maxMintAmountPublic = _newMaxMintAmount;
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

  function setWhitelistAdmin(address[] calldata _addressToWhitelist) public onlyOwner {
    for(uint256 i = 0; i < _addressToWhitelist.length; i++) {
      whitelistedAdmin[_addressToWhitelist[i]] = true;
    }
  }

  function setWhitelistSpecial(address[] calldata _addressToWhitelist) public onlyOwner {
    for(uint256 i = 0; i < _addressToWhitelist.length; i++) {
      whitelistedSpecial[_addressToWhitelist[i]] = true;
    }
  }

  function setWhitelistPresale(address[] calldata _addressToWhitelist) public onlyOwner {
    for(uint256 i = 0; i < _addressToWhitelist.length; i++) {
      whitelistedPresale[_addressToWhitelist[i]] = true;
    }
  }

  function setWinnersAddresses(address payable[] calldata _users) public onlyOwner {
    delete winnersAddresses;
    winnersAddresses = _users;
  }

  function withdraw(uint256 amount) public onlyOwner {
    (bool success, ) = payable(owner()).call{value: amount}("");
    require(success);
  }

  function withdrawAll() public onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
    require(success);
  }

  function sendRewardToWinners() public payable onlyOwner {
    for(uint256 i = 0; i < winnersAddresses.length; i++) {
        winnersAddresses[i].transfer(reward);
    }
  }

  // USEFUL FUNCTIONS PUBLIC

  function isWinner(address _user) public view returns (bool) {
    for(uint256 i = 0; i < winnersAddresses.length; i++) {
      if (winnersAddresses[i] == _user) {
        return true;
      }
    }
    return false;
  }

  function totalSupplyMax() public view returns (uint256) {
    return maxSupply;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }
}