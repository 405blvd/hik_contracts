// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
contract WhiteLists is Ownable, Pausable, ReentrancyGuard {
    mapping(address=>bool) private _minters;
    mapping(address=>bool) private _admins;
    modifier onlyAdmins(){
        require(getAdmin(msg.sender)==true,"operators in the admin only");
        _;
    }
    constructor(){
        setAdmin(msg.sender);

    }
    function setMinter(address _address) public onlyAdmins whenNotPaused{
        _minters[_address]=true;
    }
    function getMinter(address _address) public view returns(bool){
        return _minters[_address];
    }
    function deleteMinter(address _address) public onlyAdmins whenNotPaused{
        _minters[_address]=false;
    }

    function getAdmin(address _address) public whenNotPaused view returns(bool){
        return _admins[_address];
    }
    function setAdmin(address _address) public onlyOwner whenNotPaused{
        _admins[_address]=true;
    }
    function deleteAdmin(address _address) public onlyOwner whenNotPaused{
        _admins[_address]=false;
    }
    function pause() public onlyOwner{
        _pause();
    }
    function unpause() public onlyOwner{
        _unpause();
    }

}