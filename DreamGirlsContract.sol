//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;


import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DreamGirls is ERC721Enumerable, Ownable {
  using Strings for uint256;

//Basic Declarations
  string baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 3 ether; //Can be changed
  uint256 public maxSupply = 500; //Can be changed
  uint256 public maxMintAmount = 10; //Can be changed
  bool public paused = false;
  bool public revealed = true;
  string public notRevealedUri;
  uint256[] public rand;
  address payable One;
  address payable Two;
  

//Payout Declarations

  mapping(address => uint256) PayoutPercentage;
  mapping(address => uint256) UnclaimedETH;



  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    //1payout is message sender
    address payable _1,
    uint256 _1payout,
    address payable _2,
    uint256 _2payout
//More can be added
  ) ERC721(_name, _symbol) {
    require((_1payout + _2payout) == 100);
    setBaseURI(_initBaseURI);
    PayoutPercentage[_1] = _1payout;
    PayoutPercentage[_2] = _2payout;
    One = _1;
    Two = _2;
 
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintQuantity) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintQuantity > 0);
    require(_mintQuantity <= maxMintAmount);
    require(supply + _mintQuantity <= maxSupply);

    if (msg.sender != owner()) {
      require(msg.value >= cost * _mintQuantity);
    }

    for (uint256 i = 1; i <= _mintQuantity; i++) {
      uint256 randomNumber  = _generateRandom(supply + i);
      rand.push(randomNumber);
      _safeMint(msg.sender, randomNumber);
    }

    UnclaimedETH[One] = (UnclaimedETH[One] + ((msg.value * PayoutPercentage[One]) / 100));
    UnclaimedETH[Two] = (UnclaimedETH[Two] + ((msg.value * PayoutPercentage[Two]) / 100));
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
  
  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
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

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
  function withdraw() public payable {
    require(PayoutPercentage[msg.sender] > 0);
    require(UnclaimedETH[msg.sender] > 0);
    ((msg.sender).call{value: (UnclaimedETH[msg.sender])}(""));
    UnclaimedETH[msg.sender] = 0;
  }


  function transferContract(address newOwner) public onlyOwner{
    transferOwnership(newOwner);
  }

  function _generateRandom(uint256 id) private view returns (uint256)
  {
       uint256 random;
        
      random = uint256(keccak256
        (abi.encodePacked(id, block.timestamp, msg.sender))) 
        % maxSupply;

        return random;

  }
  
}
