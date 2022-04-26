// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RaffleNFT is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;

  bool public openSpecial = false;
  bool public openPresale = false;
  bool public openPublic = false;
  bool public revealed = false;

  uint256 public maxSupplySpecial = 150;
  uint256 public maxSupplyPresale = 2000;
  uint256 public maxSupplyPublic = 4900;
  uint256 public maxSupply = 5000;

  uint256 public maxMintAmountSpecial = 3;
  uint256 public maxMintAmountPresale = 2;
  uint256 public maxMintAmountPublic = 5;

  uint256 public costSpecial = 0.0001 ether;
  uint256 public costPreSale = 0.00015 ether;
  uint256 public costPublic = 0.0002 ether;

  uint256 public reward = 0.0001 ether;
  
  address[] private whitelistedAddresses;
  address payable[] public winnersAddresses;

  constructor() ERC721("Raffle", "RNFT") {
    setHiddenMetadataUri("ipfs://url/notRevealed.json");
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0, "You must mint at least 1 NFTs");
    require(supply.current() + _mintAmount <= maxSupplyPublic, "Cannot mint more than 4900 NTFs");
    _;
  }

  function mint(address _yourwallet, uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(openSpecial || openPresale || openPublic, "No active sale yet");
    uint256 supplyNow = supply.current();
    uint256 cost = costPublic;
    uint256 ownerTokenCount = balanceOf(msg.sender);

    if (openPublic) {
      require(_mintAmount <= maxMintAmountPublic && ownerTokenCount + _mintAmount <= maxMintAmountPublic, "You cannot own more than 5 NFTs");
    }
    else if (openPresale) {
      require(isWhitelisted(_yourwallet), "You are not in the whitelist, wait for the public sale");
      require(supplyNow + _mintAmount <= maxSupplyPresale, "Cannot mint more than 1000 NTFs in the private sale");
      require(_mintAmount <= maxMintAmountPresale && ownerTokenCount + _mintAmount <= maxMintAmountPresale, "You cannot own more than 3 NFTs");
      cost = costPreSale;
    }
    else if (openSpecial) {
      require(isWhitelisted(_yourwallet), "You are not in the special whitelist, wait for the public sale");
      require(supplyNow + _mintAmount <= maxSupplySpecial, "Cannot mint more than 100 NTFs in the special sale");
      require(_mintAmount <= maxMintAmountSpecial && ownerTokenCount + _mintAmount <= maxMintAmountSpecial, "You cannot own more than 2 NFTs");
      cost = costSpecial;
    }
    
    require(msg.value >= cost * _mintAmount, "The value must cover the total number of mints");

    _mintLoop(msg.sender, _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(_mintAmount > 0, "You must mint at least 1 NFTs");
    require(supply.current() + _mintAmount <= maxSupply, "Cannot mint more than 5000 NTFs");
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

  function setOpenPresale(bool _state) public onlyOwner {
    openPresale = _state;
  }

  function setOpenPublic(bool _state) public onlyOwner {
    openPublic = _state;
  }

  function setOpenSpecial(bool _state) public onlyOwner {
    openSpecial = _state;
  }

  function setCostSpecial(uint256 _newCost) public onlyOwner() {
    costSpecial = _newCost;
  }

  function setCostPreSale(uint256 _newCost) public onlyOwner() {
    costPreSale = _newCost;
  }

  function setCostPublic(uint256 _newCost) public onlyOwner() {
    costPublic = _newCost;
  }

  function setReward(uint256 _newReward) public onlyOwner() {
    reward = _newReward;
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

  function setWhitelistAddresses(address[] calldata _users) public onlyOwner {
    delete whitelistedAddresses;
    whitelistedAddresses = _users;
  }

  function setWinnersAddresses(address payable[] calldata _users) public onlyOwner {
    delete winnersAddresses;
    winnersAddresses = _users;
  }

  function withdrawAll() public onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
    require(success);
  }

  function isWhitelisted(address _user) private view returns (bool) {
    for(uint256 i = 0; i < whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _user) {
        return true;
      }
    }
    return false;
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