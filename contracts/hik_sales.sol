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

    uint256 private _serviceFee;
    //group id mapping
    mapping(uint256=>bool) private _nftGroupSaleStatus;
    mapping(uint256=>address) private _nftGroupOwner;
    mapping(uint256=>uint256) private _nftOriginalGroupId; //if it is original, set to 0
    mapping(uint256=>uint256) private _nftGroupSalePrice;
    mapping(uint256=>uint256) private _nftGroupMintAmounts;
    mapping(uint256=>uint256) private _nftGroupSoldAmounts;
    mapping(uint256=>uint256) private _nftGroupLoyalty;
    mapping(uint256=>uint256[]) private _nftGroupDateTime;
    address private _subAdmin;
    //mapping(uint256=>string) private _nftGroupURI;
    //*****************
    //token id mapping
    mapping(uint256=>uint256) private _nftTokenToGroupId;
    //*****************
    event Received(address _from, uint256 value);
    event Deposit(uint256 _tokenId, uint256 _groupId, uint256 _totalValue, uint256 _transferredServiceFee, uint256 _transferredToSeller , uint256  _transferredToRoyalty);
    WhiteLists private whiteListsAddress;
    modifier adminOnly(){
        require(whiteListsAddress.getAdmin(msg.sender)==true,"operators in the admins only");
        _;
    }
    constructor(
        string memory _name,
        string memory _symbol,
        address _whiteListsAddress
    )ERC721(_name,_symbol){
        whiteListsAddress = WhiteLists(_whiteListsAddress);
        _serviceFee=500;
    }
    function setSubAdmin(address _subAdminAddress) public onlyAdmins {
        _subAdmin=_subAdminAddress;
    }
    function getServiceFee() public view returns(uint256){
        return _serviceFee;
    }
    function setServiceFee(uint256 _newServiceFee) public onlyOwner{
        //10000 => 100%, 1000=>10%, 500 => 5%, 100% => 1%
        _serviceFee=_newServiceFee;
    }
    //set group owner && get group owner
    function getGroupOwner(uint256 _groupId) public view returns(address){
        return _nftGroupOwner[_groupId];
    }
    //set original owner && get original owner
    function getOriginalGroup(uint256 _groupId) public view returns(uint256){
        return _nftOriginalGroupId[_groupId];
    }
    //**********************************
    //set sales price && get sales price
    function getSalePrice(uint256 _groupId) public view returns(uint256){
        return _nftGroupSalePrice[_groupId];
    }
    function setSalePrice(uint256 _groupId, uint256 _price) public{
        require(whiteListsAddress.getAdmin(msg.sender)==true|| msg.sender==_subAdmin,"operators in the admins only or group Owner");
        _nftGroupSalePrice[_groupId]=_price;
    }
    // function getDateTime(uint256 _groupId) public view returns(uint256[]memory){
    //     return _nftGroupDateTime[_groupId];
    // }
    function setDateTime(uint256 _groupId, uint256 _startTime, uint256 _endTime) public{
        require(whiteListsAddress.getAdmin(msg.sender)==true || msg.sender==_subAdmin,"operators in the admins only or group Owner");
        _nftGroupDateTime[_groupId]=[_startTime,_endTime];
    }
    //
    //**********************************
    //set loyalty && get loyalty
    function getLoyalty(uint256 _groupId) public view returns(uint256){
        return _nftGroupLoyalty[_groupId];
    }
    //**********************************
    //set metadata && get metadata
    // function getMetaData(uint256 _groupId) public view returns(string memory){
    //     return _nftGroupURI[_groupId];
    // }
    // function setMetaData(uint256 _groupId, string memory _uri) public adminOnly{
    //     _nftGroupURI[_groupId]=_uri;
    // }
    //set sale status && get sale status
    function getSaleStatus(uint256 _groupId) public view returns(bool){
        return _nftGroupSaleStatus[_groupId];
    }
    function setSaleStatus(uint256 _groupId, bool _status) public {
        require(whiteListsAddress.getAdmin(msg.sender)==true || msg.sender==_subAdmin,"the user is not granted");
        _nftGroupSaleStatus[_groupId]=_status;
    }
    //**********************************
    
    //**********************************
    
    //**********************************
    //set nft token to gorup id
    function getNftTokenToGroupId(uint256 _nftTokenId) public view returns(uint256){
        return _nftTokenToGroupId[_nftTokenId];
    }
    //**********************************

    //setup sales once the mint requests are approved!
    function setupSale(uint256 _groupId,uint256 _originalGroupId,
    address _groupOwner, uint256 _price,uint256 _loyalty, 
    uint256 _mintAmounts,uint256 _saleStartTime, uint256 _saleEndTime) external adminOnly whenNotPaused {
        //setGroupOwner(_groupId,_groupOwner);
        _nftGroupOwner[_groupId]=_groupOwner;
        _nftOriginalGroupId[_groupId]=_originalGroupId;
        setSalePrice(_groupId,_price);
        _nftGroupLoyalty[_groupId]=_loyalty;
        _nftGroupMintAmounts[_groupId]=_mintAmounts;
        //setMetaData(_groupId,_metadataUri);
        setSaleStatus(_groupId,true);
        setDateTime(_groupId,_saleStartTime,_saleEndTime);
        //whiteListsAddress.setMinter(_groupOwner);
    }

    function buyNft(uint256 _groupId,string memory _metadataUri) public payable nonReentrant whenNotPaused returns(uint256){
        require(whiteListsAddress.getMinter(getGroupOwner(_groupId))==true,"the seller items are suspended");
        require(getSaleStatus(_groupId)==true,"the item is not on sale");
        require(getGroupOwner(_groupId) != address(0),"group ID is not available");
        require(_nftGroupMintAmounts[_groupId] >= _nftGroupSoldAmounts[_groupId],"sold out");
        require(msg.sender != getGroupOwner(_groupId),"unable to buy own nft");
        require(getSalePrice(_groupId)>0,"unable buy this item");
        require(msg.value >= getSalePrice(_groupId),"insufficient fund");
        require(_nftGroupDateTime[_groupId][0]<=block.timestamp && _nftGroupDateTime[_groupId][1]>block.timestamp,"time expired");
        uint256 serviceFee= msg.value*getServiceFee()/10000;
        uint256 loyaltyFee=0;
        //loyalty
        if(getOriginalGroup(_groupId)>0){
            loyaltyFee=msg.value*getLoyalty(getOriginalGroup(_groupId))/10000;
            (bool success1, )= payable(address(getGroupOwner(getOriginalGroup(_groupId)))).call{value:loyaltyFee}("");
            require(success1, "Transfer failed.");
        }
        //seller
        (bool success2, )= payable(address(getGroupOwner(_groupId))).call{value:msg.value-serviceFee-loyaltyFee}("");
        require(success2, "Transfer failed.");
        _tokenId.increment();
        uint256 newTokenId = _tokenId.current();
        _safeMint(msg.sender,newTokenId);
        _setTokenURI(newTokenId,_metadataUri);
        _nftTokenToGroupId[newTokenId]=_groupId;
        _nftGroupSoldAmounts[_groupId]+=1;
        //(uint256 _tokenId, uint256 _groupId, uint256 _totalValue, uint256 _transferredToRoyalty,
        //uint256 _transferredToSeller , uint256 _transferredServiceFee);

        emit Deposit(newTokenId,_groupId,msg.value,serviceFee,msg.value-serviceFee-loyaltyFee,loyaltyFee);
        return newTokenId;
    }
    receive() external payable {
         // custom function code
         emit Received(msg.sender, msg.value);
    }
    function withdraw(uint256 amount) external adminOnly whenNotPaused{
        require(amount<=address(this).balance,"amount is exceeded");
        (bool success, )=payable(whiteListsAddress.owner()).call{value:amount}("");
        require(success, "Transfer failed.");

    }
    function totalSupply() public view returns(uint256){
        return _tokenId.current();
    }
    function burn(uint256 _burnTokenId) public whenNotPaused {
        require(whiteListsAddress.getAdmin(msg.sender)==true || ownerOf(_burnTokenId)==msg.sender,"not qualified to burn");
        _burn(_burnTokenId);
    }
    function balance() public view returns(uint256) {
        return address(this).balance;
    }
}
