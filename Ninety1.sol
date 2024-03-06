// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import "./EnefteOwnership.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./IFold.sol";
import "./IFoldStaking.sol";
import "./ITwenty6Fifty2.sol";

/*
* @title Ninety1
* @author lileddie.eth / Enefte Studio
*/
contract Ninety1 is ERC1155, EnefteOwnership {

    uint256 public EMISSIONS = 1000 ether;
    ITwenty6Fifty2 TWENTY; 
    IFold FOLD;
    IFoldStaking foldStaking;
    mapping(uint => uint) handMultiplier;
    string private _name;
    string private _symbol;
    uint256[] mintIds;
    uint256[] mintAmounts;
    uint256 private constant FOLD_TOKEN_PRECISION = 1e18;
    

    modifier onlyTwenty() {
        if(msg.sender != address(TWENTY)){
            revert("Only twenty contract allowed.");
        }
        _;
    }

    /**
    * @notice mint the 91 sub-NFTs when a 2652 is folded.
    *
    * @param _folder address of person folding
    */
    function mint(address _folder) external onlyTwenty  {
        _mintBatch(_folder, mintIds, mintAmounts,"");
    }

    function fold(uint _tokenId, uint _amount) external {
        if(balanceOf(msg.sender, _tokenId) < _amount){
            revert("Not enough tokens");
        }
        FOLD.transfer(msg.sender,(_amount*EMISSIONS));
        _burn(msg.sender, _tokenId, _amount);
    }

    /**
    * @notice sets the URI of where metadata will be hosted, gets appended with the token id
    *
    * @param _uri the amount URI address
    */
    function setBaseURI(string memory _uri) external onlyOwner {
        _setURI(_uri);
    }

    /**
    * @notice set the address for the smart contracts
    *
    */
    function setContracts(address _address2652, address _addressFold, address _addressStaking) external onlyOwner {
        TWENTY = ITwenty6Fifty2(_address2652);
        FOLD = IFold(_addressFold);
        foldStaking = IFoldStaking(_addressStaking);
    }
    
    
    function setMultipliers(uint[] calldata _tokenIds, uint _tier) external onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            handMultiplier[_tokenIds[i]] = _tier;
        }
    }


    function calculateEmissions(uint256[] memory ids, uint256[] memory amounts) internal view returns (uint256 totalEmissions) {
        uint _emissions = 0;
        uint shareEmissions = EMISSIONS/FOLD_TOKEN_PRECISION;
        for(uint i = 0;i < ids.length;i++){
            uint tokenId = ids[i];
            uint amount = amounts[i];
            uint multiplier = handMultiplier[tokenId];
            _emissions += (shareEmissions * amount) * multiplier;
        }
        return _emissions;
    }

    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        uint256 totalEmissions = calculateEmissions(ids,amounts);
        if(from == address(0)){ //minted
            foldStaking.deposit(totalEmissions,to);
        }   
        else if(to == address(0)){ //burned
            foldStaking.withdraw(totalEmissions,from);
        }  
        else {  //transferred
            foldStaking.withdraw(totalEmissions,from);
            foldStaking.deposit(totalEmissions,to);
        }  
    }

   
   
    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    constructor() ERC1155("https://enefte.info/n1/n1.php?token_id=") {
        setOwner(msg.sender);
        _name = "Ninety1";
        _symbol = "91";
        for(uint256 i=1;i<=91;i++){
            mintIds.push(i);
            mintAmounts.push(1);
        }
    }

}