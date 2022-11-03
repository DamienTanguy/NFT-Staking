// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NftStakingERC20 is ERC20, Ownable {

    mapping(address => bool) admins; //to store the address of the NFT contract ERC721A, only this contract can mint the token of staking 

    constructor() ERC20("Dam's token", "DTT") {}

    function mint(address _to, uint _amount) external { //only the NFT contract ERC721A can mint the token ERC20 --> so external because the NFT contract has to have access to this function
        require(admins[msg.sender], "Can't mint if not admin");
        _mint(_to, _amount);
    }

    function addAdmin(address _admin) external onlyOwner { //to add the NFT contract address as admin to execute the mint function
        admins[_admin] = true;
    }

    function removeAdmin(address _admin) external onlyOwner {
        admins[_admin] = false;
    }

}
