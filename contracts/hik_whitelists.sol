// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
contract WhiteLists is Ownable, Pausable, ReentrancyGuard {
    mapping(address=>bool) private _minters;
    mapping(address=>bool) private _admins;
    mapping(address=>bool) private _subAdmin;
    //address public subAdmins;
    modifier onlyAdmins(){
        require(_admins[msg.sender]==true,"operators in the admin only");
        _;
    }
    constructor(){
        _admins[msg.sender]=true;
        _minters[msg.sender]=true;
        _subAdmin[msg.sender]=true;

    }
    function setSubAdmin(address _address, bool _status) external onlyAdmins whenNotPaused{
        _subAdmin[_address]=_status;
    }
    function getSubAdmin(address _address) external view returns(bool){
        return _subAdmin[_address];
    }
    // function deleteSubAdmin(address _address) public onlyAdmins whenNotPaused{
    //     _subAdmin[_address]=false;
    // }
    function setMinter(address _address, bool _status) external onlyAdmins whenNotPaused{
        _minters[_address]=_status;
    }
    function getMinter(address _address) external view returns(bool){
        return _minters[_address];
    }
    // function deleteMinter(address _address) external onlyAdmins whenNotPaused{
    //     _minters[_address]=false;
    // }
    function getAdmin(address _address) external whenNotPaused view returns(bool){
        return _admins[_address];
    }
    function setAdmin(address _address,bool _status) external onlyOwner whenNotPaused{
        _admins[_address]=_status;
    }
    // function deleteAdmin(address _address) external onlyOwner whenNotPaused{
    //     _admins[_address]=false;
    // }

    function pause() public onlyOwner{
        _pause();
    }
    function unpause() public onlyOwner{
        _unpause();
    }


}
