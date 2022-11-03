// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "./IERC721A.sol";
import "./ERC721AQueryable.sol"; // to use the function tokensOfOwner --> know the owner of the tokens
import "./IERC721AQueryable.sol";

contract NftStakingERC721A is ERC721A, ERC721AQueryable {

    constructor() ERC721A("Dam's NFT","DTT NFT") {}

    function mint(uint quantity) external payable {
        _safeMint(msg.sender, quantity);
    }

}
