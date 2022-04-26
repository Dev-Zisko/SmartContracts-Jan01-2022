// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "rarible/royalties/contracts/LibPart.sol";
import "rarible/royalties/contracts/LibRoyaltiesV2.sol";

contract NFTRoyalties is ERC721, Ownable, RoyaltiesV2Impl {
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

  uint256 public maxSupplySpecial = 100;
  uint256 public maxSupplyPresale = 1000;
  uint256 public maxSupply = 5000;

  uint256 public maxMintAmountSpecial = 2;
  uint256 public maxMintAmountPresale = 5;
  uint256 public maxMintAmountPublic = 100;

  uint256 public costSpecial = 1 ether;
  uint256 public costPreSale = 2 ether;
  uint256 public costPublic = 3 ether;

  address[] public whitelistedAddresses;

  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  constructor() ERC721("NFTRoyalties", "NFTR") {
    setHiddenMetadataUri("ipfs://url/notRevealed.json");
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0, "You must mint at least 1 NFTs");
    require(supply.current() + _mintAmount <= maxSupply, "Cannot mint more than 5000 NTFs");
    _;
  }

  function mint(address _yourwallet, uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(openSpecial || openPresale || openPublic, "No sale is open yet");
    uint256 cost = costPublic;

    if (openPublic) {
      require(_mintAmount <= maxMintAmountPublic && balanceOf(msg.sender) + _mintAmount <= maxMintAmountPublic, "You cannot own more than 5 NFTs");
    }
    else if (openPresale) {
      require(isWhitelisted(msg.sender), "You are not in the whitelist, wait for the public sale");
      require(supply.current() + _mintAmount <= maxSupplyPresale, "Cannot mint more than 1000 NTFs in the private sale");
      require(_mintAmount <= maxMintAmountPresale && balanceOf(msg.sender) + _mintAmount <= maxMintAmountPresale, "You cannot own more than 3 NFTs");
      cost = costPreSale;
    }
    else if (openSpecial) {
      require(isWhitelisted(msg.sender), "You are not in the special whitelist, wait for the public sale");
      require(supply.current() + _mintAmount <= maxSupplySpecial, "Cannot mint more than 100 NTFs in the special sale");
      require(_mintAmount <= maxMintAmountSpecial && balanceOf(msg.sender) + _mintAmount <= maxMintAmountSpecial, "You cannot own more than 2 NFTs");
      cost = costSpecial;
    }
    
    require(msg.value >= cost * _mintAmount, "The value must cover the total number of mints");

    _mintLoop(msg.sender, _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory)
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

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory)
  {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
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

  //configure royalties for Rariable
  function setRoyalties(uint _tokenId, address payable _royaltiesRecipientAddress, uint96 _percentageBasisPoints) public onlyOwner {
    LibPart.Part[] memory _royalties = new LibPart.Part[](1);
    _royalties[0].value = _percentageBasisPoints;
    _royalties[0].account = _royaltiesRecipientAddress;
    _saveRoyalties(_tokenId, _royalties);
  }

  //configure royalties for Mintable using the ERC2981 standard
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
    //use the same royalties that were saved for Rariable
    LibPart.Part[] memory _royalties = royalties[_tokenId];
    if(_royalties.length > 0) {
      return (_royalties[0].account, (_salePrice * _royalties[0].value) / 10000);
    }
    return (address(0), 0);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
        return true;
    }
    if(interfaceId == _INTERFACE_ID_ERC2981) {
      return true;
    }
    return super.supportsInterface(interfaceId);
  }

  // USEFUL FUNCTIONS ONLYOWNER

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
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

  function setCostSpecial(uint256 _newCost) public onlyOwner() {
    costSpecial = _newCost;
  }

  function setCostPreSale(uint256 _newCost) public onlyOwner() {
    costPreSale = _newCost;
  }

  function setCostPublic(uint256 _newCost) public onlyOwner() {
    costPublic = _newCost;
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

  function withdraw(uint256 amount) public onlyOwner {
    (bool success, ) = payable(owner()).call{value: amount}("");
    require(success);
  }

  function withdrawAll() public onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
    require(success);
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

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }
}