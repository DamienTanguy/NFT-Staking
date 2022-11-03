// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./NftStakingERC721A.sol";
import "./NftStakingERC20.sol";

//make the link between the NFT contract and the tokenERC20 contract
//contract to deployed after the 2 other contracts
contract NftStaking {

    uint totalStaked;

    struct Staking { //represent 1 nft staked
        uint24 tokenId;
        uint48 stakingStartTime;
        address owner;
    }

    //TokenId (uint) --> Staking
    mapping(uint => Staking) NFTisStaked;

    uint rewardPerHour = 10000; //100000/10**18 ERC20 token reward by hour received by the staker

    NftStakingERC20 token; //pointeur vers le contrat
    NftStakingERC721A nft; //pointeur vers le contrat

    event Staked(address indexed owner, uint tokenId, uint value); //value --> timestamp
    event Unstaked(address indexed owner, uint tokenId, uint value); //value --> timestamp
    event Claimed(address indexed owner, uint amount);

    constructor(NftStakingERC20 _token, NftStakingERC721A _nft){ //address of the 2 contracts
        token = _token;
        nft = _nft;
    }

    function Stake(uint[] calldata tokenIds) external {
        totalStaked += tokenIds.length;
        uint tokenId;
        for(uint i = 0; i < tokenIds.length; i++){
            tokenId = tokenIds[i];
            require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");
            require(NFTisStaked[tokenId].stakingStartTime == 0, "the NFT is already staked");
            
            nft.transferFrom(msg.sender,address(this),tokenId);//Function from ERC721A contract
            emit Staked(msg.sender, tokenId, block.timestamp);
            
            NFTisStaked[tokenId] = Staking({
                tokenId: uint24(tokenId),
                stakingStartTime: uint48(block.timestamp),
                owner: msg.sender
            });

        }
    }

    //internal because only call after a claim --> for the user to be sure to claim all his rewards before unstaking
    function _unstakMany(address owner, uint[] calldata tokenIds) internal {
        totalStaked -= tokenIds.length;
        uint tokenId;
        for(uint i = 0; i < tokenIds.length; i++){
            tokenId = tokenIds[i];
            require(NFTisStaked[tokenId].owner == msg.sender, "Not the owner"); 

            emit Unstaked(owner, tokenId, block.timestamp);
            delete NFTisStaked[tokenId];

            nft.transferFrom(address(this), owner, tokenId);
        }
    }

    function claim(uint[] calldata tokenIds) external {
        _claim(msg.sender, tokenIds, false);
    }
    
    function unstake(uint[] calldata tokenIds) external {
        _claim(msg.sender, tokenIds, true);
    }

    function _claim(address owner, uint[] calldata tokenIds, bool _unstake) internal {
        uint tokenId;
        uint earned;
        uint totalEarned;

        for(uint i = 0; i < tokenIds.length; i++){
            tokenId = tokenIds[i];
            Staking memory thisStake = NFTisStaked[tokenId];
            require(thisStake.owner == owner, "Not the owner of the nft, you can't claim");

            uint stakingStartime = thisStake.stakingStartTime;

            earned = ((block.timestamp - stakingStartime) * rewardPerHour) / 3600;
            totalEarned += earned;

            NFTisStaked[tokenId] = Staking({
                tokenId: uint24(tokenId),
                stakingStartTime: uint48(block.timestamp),
                owner: owner
            });
        }

        if(totalEarned > 0){
            token.mint(owner, totalEarned);
        }
        if(_unstake){
            _unstakMany(owner, tokenIds);
        }
        emit Claimed(owner, totalEarned);
    }

    function getRewardAmount(address owner, uint[] calldata tokenIds) external view returns(uint){
        uint tokenId;
        uint earned;
        uint totalEarned;

        for(uint i = 0; i < tokenIds.length; i++){
            tokenId = tokenIds[i];
            Staking memory thisStake = NFTisStaked[tokenId];
            require(thisStake.owner == owner, "Not the owner of the nft, you can't claim");

            uint stakingStartime = thisStake.stakingStartTime;

            earned = ((block.timestamp - stakingStartime) * rewardPerHour) / 3600;
            totalEarned += earned;
        }
        return totalEarned;
    }

    function tokenStakedByOwner(address owner) external view returns(uint[] memory){
        uint totalSupply = nft.totalSupply(); //nb NFT sold
        uint[] memory tmp = new uint[](totalSupply);
        uint index = 0;

        for(uint i = 0; i < totalSupply; i++){
            if(NFTisStaked[i].owner == owner){
                tmp[index] = i;
                index++;
            }
        }

        uint[] memory tokens = new uint[](index);
        for(uint i = 0; i < index; i++){
            tokens[i] = tmp[i];
        }

        return tokens;
    }

}
