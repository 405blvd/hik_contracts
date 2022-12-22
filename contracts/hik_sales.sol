// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./hik_whitelists.sol";
contract HikSales is ERC721URIStorage, Ownable, WhiteLists {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;

    uint256 private serviceFee;
    //group id mapping
    mapping(uint256=>bool) public _nftGroupSaleStatus;
    mapping(uint256=>address) private _nftGroupOwner;
    mapping(uint256=>uint256) private _nftOriginalGroupId; //if it is original, set to 0
    mapping(uint256=>uint256) public _nftGroupSalePrice;
    mapping(uint256=>uint256) public _nftGroupMintAmounts;
    mapping(uint256=>uint256) public _nftGroupSoldAmounts;
    mapping(uint256=>uint256) public _nftGroupLoyalty;
    mapping(uint256=>uint256[]) public _nftGroupDateTime;
    //mapping(uint256=>string) private _nftGroupURI;
    //*****************
    //token id mapping
    //mapping(uint256=>uint256) private _nftTokenToGroupId;
    //*****************
    event Received(address _from, uint256 value);
    event Deposit(uint256 _tokenId, uint256 _groupId, uint256 _totalValue, uint256 _transferredServiceFee, uint256 _transferredToSeller , uint256  _transferredToRoyalty);
    WhiteLists private whiteListsAddress;
    modifier adminOnly(){
        require(whiteListsAddress.getAdmin(msg.sender)==true,"operators in the admins only");
        _;
    }
    modifier subAdminOrAdminOnly(){
        require(whiteListsAddress.getSubAdmin(msg.sender)==true || whiteListsAddress.getAdmin(msg.sender)==true,"operators in the subAdmin or Admin only");
        _;


    }
    constructor(
        string memory _name,
        string memory _symbol,
        address _whiteListsAddress
    )ERC721(_name,_symbol){
        whiteListsAddress = WhiteLists(_whiteListsAddress);
        serviceFee=500;
    }
    // function getServiceFee() public view returns(uint256){
    //     return _serviceFee;
    // }
    function setServiceFee(uint256 _newServiceFee) external onlyOwner{
        //10000 => 100%, 1000=>10%, 500 => 5%, 100 => 1%
        serviceFee=_newServiceFee;
    }
    //set group owner && get group owner
    // function getGroupOwner(uint256 _groupId) public view returns(address){
    //     return _nftGroupOwner[_groupId];
    // }
    //set original owner && get original owner
    // function getOriginalGroup(uint256 _groupId) public view returns(uint256){
    //     return _nftOriginalGroupId[_groupId];
    // }
    //**********************************
    //set sales price && get sales price
    // function getSalePrice(uint256 _groupId) public view returns(uint256){
    //     return _nftGroupSalePrice[_groupId];
    // }
    // function getSaleQuantityAndSoldQuantity(uint256 _groupId) external view returns(uint256[2] memory){
    //     return [_nftGroupMintAmounts[_groupId],_nftGroupSoldAmounts[_groupId]];
    // }
    function setSalePrice(uint256 _groupId, uint256 _price) external subAdminOrAdminOnly{
        //require(whiteListsAddress.getAdmin(msg.sender)==true|| msg.sender==_subAdmin,"operators in the admins only or group Owner");
        _nftGroupSalePrice[_groupId]=_price;
    }
    // function getDateTime(uint256 _groupId) public view returns(uint256[]memory){
    //     return _nftGroupDateTime[_groupId];
    // }
    // function setDateTime(uint256 _groupId, uint256 _startTime, uint256 _endTime) public subAdminOrAdminOnly{
    //     //require(whiteListsAddress.getAdmin(msg.sender)==true || msg.sender==_subAdmin,"operators in the admins only or group Owner");
    //     _nftGroupDateTime[_groupId]=[_startTime,_endTime];
    // }
    //
    //**********************************
    //set loyalty && get loyalty
    // function getLoyalty(uint256 _groupId) public view returns(uint256){
    //     return _nftGroupLoyalty[_groupId];
    // }
    //**********************************
    //set metadata && get metadata
    // function getMetaData(uint256 _groupId) public view returns(string memory){
    //     return _nftGroupURI[_groupId];
    // }
    // function setMetaData(uint256 _groupId, string memory _uri) public adminOnly{
    //     _nftGroupURI[_groupId]=_uri;
    // }
    //set sale status && get sale status
    // function getSaleStatus(uint256 _groupId) public view returns(bool){
    //     return _nftGroupSaleStatus[_groupId];
    // }
    function setSaleStatus(uint256 _groupId, bool _status) external subAdminOrAdminOnly {
        //require(whiteListsAddress.getAdmin(msg.sender)==true || whiteListsAddress.getSubAdmin(msg.sender)==true,"the user is not granted");
        _nftGroupSaleStatus[_groupId]=_status;
    }
    //**********************************
    
    //**********************************
    
    //**********************************
    //set nft token to gorup id
    // function getNftTokenToGroupId(uint256 _nftTokenId) external view returns(uint256){
    //     return _nftTokenToGroupId[_nftTokenId];
    // }
    //**********************************

    //setup sales once the mint requests are approved!
    function setupSale(uint256 _groupId,uint256 _originalGroupId,
    address _groupOwner, uint256 _price,uint256 _loyalty, 
    uint256 _mintAmounts,uint256 _saleStartTime, uint256 _saleEndTime) external adminOnly whenNotPaused {
        //setGroupOwner(_groupId,_groupOwner);
        //require(whiteListsAddress.getAdmin(msg.sender)==true || whiteListsAddress.getSubAdmin(msg.sender)==true,"operators in the admins only or group Owner");
        _nftGroupOwner[_groupId]=_groupOwner;
        _nftOriginalGroupId[_groupId]=_originalGroupId;
        _nftGroupSalePrice[_groupId]=_price;
        _nftGroupLoyalty[_groupId]=_loyalty;
        _nftGroupMintAmounts[_groupId]=_mintAmounts;
        //setMetaData(_groupId,_metadataUri);
        _nftGroupSaleStatus[_groupId]=true;
        _nftGroupDateTime[_groupId]=[_saleStartTime,_saleEndTime];
        //whiteListsAddress.setMinter(_groupOwner);
    }

    function buyNft(uint256 _groupId,string memory _metadataUri) external payable nonReentrant whenNotPaused returns(uint256){
        require(whiteListsAddress.getMinter(_nftGroupOwner[_groupId])==true,"the seller items are suspended");
        require(_nftGroupSaleStatus[_groupId]==true,"the item is not on sale");
        require(_nftGroupOwner[_groupId] != address(0),"group ID is not available");
        require(_nftGroupMintAmounts[_groupId] > _nftGroupSoldAmounts[_groupId],"sold out");
        require(msg.sender != _nftGroupOwner[_groupId],"unable to buy own nft");
        require(_nftGroupSalePrice[_groupId]>0,"unable buy this item");
        require(msg.value >= _nftGroupSalePrice[_groupId],"insufficient fund");
        require(_nftGroupDateTime[_groupId][0]<=block.timestamp && _nftGroupDateTime[_groupId][1]>block.timestamp,"time expired");
        uint256 _serviceFee= msg.value*serviceFee/10000;
        uint256 loyaltyFee=0;
        //loyalty
        if(_nftOriginalGroupId[_groupId]>0){
            loyaltyFee=msg.value*_nftGroupLoyalty[_nftOriginalGroupId[_groupId]]/10000;
            if(loyaltyFee>0){
                (bool success1, )= payable(address(_nftGroupOwner[_nftOriginalGroupId[_groupId]])).call{value:loyaltyFee}("");
                require(success1, "Transfer loyalty failed.");
            }
            
        }
        //seller
        (bool success2, )= payable(address(_nftGroupOwner[_groupId])).call{value:msg.value-_serviceFee-loyaltyFee}("");
        require(success2, "Transfer to Seller failed.");
        _tokenId.increment();
        uint256 newTokenId = _tokenId.current();
        _safeMint(msg.sender,newTokenId);
        _setTokenURI(newTokenId,_metadataUri);
        //_nftTokenToGroupId[newTokenId]=_groupId;
        _nftGroupSoldAmounts[_groupId]+=1;
        //(uint256 _tokenId, uint256 _groupId, uint256 _totalValue, uint256 _transferredToRoyalty,
        //uint256 _transferredToSeller , uint256 _transferredServiceFee);

        emit Deposit(newTokenId,_groupId,msg.value,_serviceFee,msg.value-_serviceFee-loyaltyFee,loyaltyFee);
        return newTokenId;
    }
    receive() external payable {
         // custom function code
         emit Received(msg.sender, msg.value);
    }
    function withdraw(uint256 amount) external payable adminOnly whenNotPaused{
        require(amount<=address(this).balance,"amount is exceeded");
        (bool success, )=payable(owner()).call{value:amount}("");
        require(success, "Transfer failed.");

    }
    // function totalSupply() public view returns(uint256){
    //     return _tokenId.current();
    // }
    function burn(uint256 _burnTokenId) external subAdminOrAdminOnly whenNotPaused {
        //require(whiteListsAddress.getAdmin(msg.sender)==true || ownerOf(_burnTokenId)==msg.sender,"not qualified to burn");
        _burn(_burnTokenId);
    }
    function balance() external view returns(uint256) {
        return address(this).balance;
    }
}
