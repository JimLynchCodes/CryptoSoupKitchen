// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "hardhat/console.sol";
import "./2_Owner.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract CryptoSoupKitchen is VRFConsumerBase {
    address owner = msg.sender;
    address public genericAddress;
    ERC721Enumerable public genericAddressERC721;
    address[] nft_collections = [address(0), address(0)];
    address[] nft_token_addresses;
    uint256 nft_token_count;
    uint256 contractBalance;
    uint256 ownerBalance;
    uint256[] public numbers;
    address[] public addresses; // address[] public nft_collections;
    ERC721[] public erc721Addresses;
    string[] address_id_combos;
    uint256 balance_test = 8;
    uint256 nft_collections_next_index;
    uint256 total_num_of_nft_tokens_to_give_away;
    mapping(address => bool) nft_address_seen_before;
    mapping(address => uint256) nft_indices;

    mapping(address => uint256[]) tokensForNft;
    mapping(address => uint256[]) nft_tokens_owned_by_contract;
    address[] nft_featured_collections;
    uint256[][] nft_token_Ids_to_give_away;
    uint256[] nft_num_of_token_ids_to_give_away;
    event AskedForSoup(address);
    ytes32 public keyHash;
    uint256 public fee;
    uint256 public randomResult;
    address mainnetLinkAddress = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;
    address testnetLinkAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address mainnetVrfCoordinator = 0x3d2341ADb2D31f1c5530cDC622016af293177AE0;
    address testnetVrfCoordinator = 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255;
    bytes32 mainnetOracleKeyHash =
        0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
    bytes32 testnetOracleKeyHash =
        0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
    uint256 MUMBAI_TESTNET_CHAINID = 80001;
    // address __linkTokenAddress = getChainId() == MUMBAI_TESTNET_CHAINID ? testnetLinkAddress : mainnetLinkAddress; // address __vrfCoordinatorAddress = getChainId() == MUMBAI_TESTNET_CHAINID ? testnetVrfCoordinator : mainnetVrfCoordinator; // bytes32 __oracleKeyhash = getChainId() == MUMBAI_TESTNET_CHAINID ? testnetOracleKeyHash : mainnetOracleKeyHash;
    address __linkTokenAddress = testnetLinkAddress;
    address __vrfCoordinatorAddress = testnetVrfCoordinator;
    bytes32 __oracleKeyhash = testnetOracleKeyHash;
    uint256 jackpot;
    
    uint256 chance_of_winning_jackpot = 50000;

    constructor() VRFConsumerBase(__vrfCoordinatorAddress, __linkTokenAddress) {
        keyHash = __oracleKeyhash;

        fee = 0.0001 * 10**18; // 0.0001 Link

        // Creates a New Game when deployed (and then automatically when games end) // createNewBoard();

        // setup game
    }

    function getNftCollectionAtIndex(uint256 index)
        external
        view
        returns (address)
    {
        return nft_collections[index];
    }

    function getNftTokenAtIndex(uint256 index) external view returns (address) {
        return nft_token_addresses[index];
    }

    function getNumberAtIndex(uint256 index) external view returns (uint256) {
        return numbers[index];
    }

    function getGenericAddressAtIndex(uint256 index)
        external
        view
        returns (address)
    {
        return addresses[index];
    }

    function updateNftCollections(address[] memory newCollections) external {
        nft_collections = newCollections;
    }

    function storeNumbers(uint256[] calldata _numbers) external {
        numbers = _numbers;
    }

    function storeGenericAddresses(address[] calldata _addresses) external {
        addresses = _addresses;
    }

    function storeGenericErc20Addresses(address _erc721Addresses) external {
        // erc721Addresses = _erc721Addresses;
        
        genericAddress = _erc721Addresses;
        genericAddressERC721 = ERC721Enumerable(_erc721Addresses);
        
    }

    function storeTokenIdsToGiveAwayForNft(
        address nft_address,
        uint256[] calldata token_ids
    ) external {

        // TODO - make sure contract is the owner of the token_ids passed in.
        
        // WARNING: Unbounded loop in Solidity is kind of an anti-pattern 
        // for (uint i=0; i<_erc721Addresses.length; i++) { 
        //     contractBalance = genericAddressERC721.balanceOf(address(this)); 
        //     ownerBalance = genericAddressERC721.balanceOf(owner);
        // }

        if (!nft_address_seen_before[nft_address]) {
            console.log("new token!");
            
            nft_indices[nft_address] = nft_collections_next_index;
            
            nft_collections[nft_collections_next_index] = nft_address;
            
            nft_token_Ids_to_give_away[nft_collections_next_index] = token_ids;

            nft_num_of_token_ids_to_give_away[
                nft_collections_next_index
            ] = token_ids.length;
            
            // total_num_of_nft_tokens_to_give_away += token_ids.length;
            
            nft_address_seen_before[nft_address] = true;
            
            nft_collections_next_index++;
        } else {
            uint256 nft_index = nft_indices[nft_address];
            total_num_of_nft_tokens_to_give_away -= nft_num_of_token_ids_to_give_away[
                nft_index
            ];
            total_num_of_nft_tokens_to_give_away += token_ids.length;
            nft_token_Ids_to_give_away[nft_index] = token_ids;
            nft_num_of_token_ids_to_give_away[nft_index] = token_ids.length;
        }
    }

    modifier paidOne() {
        require(
            msg.value == 1,
            "Please send one token with your request for soup!"
        );
        _;
    }

    function askForSoup() external payable paidOne {
        emit AskedForSoup(msg.sender);
        unfulfilledSoupPayments[msg.sender] += msg.value;
        bytes32 _requestId = requestRandomness(keyHash, fee);
        requestsForSoup[_requestId] = msg.sender;
        jackpot += msg.value / 10;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        address requestedBy = requestsForSoup[requestId];

        bool isJackpotWinner = randomness % chance_of_winning_jackpot == 1;

        if (isJackpotWinner) {
            
            emit JackpotWinner(requestedBy, jackpot);
            
            (bool success, ) = payable(requestedBy).call{
                value: (jackpot)
            }("");
            require(success);

            jackpot = 1;
        }
        else {

           uint randomlyChosenNftTokenIndex = (randomness % total_num_of_nft_tokens_to_give_away) + 1;

           // find what collection token corresponds to

        //    uint collection_index;
        //    bool collection_already_counted;

           uint256 tokenCount;

           for (uint i=0; i<nft_collections_next_index; i++) { 

                // nft_collections[i]

                tokenCount += nft_num_of_token_ids_to_give_away[i];


                if (tokenCount >= randomlyChosenNftTokenIndex) {

                    nftAddress = nft_collections[i];

                    tokenIndex = (randomness % nft_num_of_token_ids_to_give_away[i]) + 1;

                    // transfer nft
                    uint tokenId = nft_token_Ids_to_give_away[i][tokenIndex];
           
                    ERC721(nftAddress).transferFrom(this, requestedBy, tokenId);

                    // remove tokenID from array (swap n' pop)
                    
                    uint oldLastTokenIdValue = nft_token_Ids_to_give_away[i][nft_num_of_token_ids_to_give_away[i]];

                    nft_token_Ids_to_give_away[tokenIndex] = oldLastTokenIdValue;

                    nft_token_Ids_to_give_away.pop();

                    nft_num_of_token_ids_to_give_away[i]--;

                }

                // contractBalance = genericAddressERC721.balanceOf(address(this)); 
                // ownerBalance = genericAddressERC721.balanceOf(owner);

                // if ()


            }
           


        }
    }

    function tokensIdForNftOwedByContract(address nft_address)
        public
        view
        returns (uint256[] memory)
    {
        return tokensForNft[nft_address];
    }

    function numberOfTokensIdForNftOwedByContract(address nft_address)
        public
        view
        returns (uint256)
    {
        return tokensForNft[nft_address].length;
    }

    function getCurrentJackpotAmount() external view returns (uint256) {
        return jackpot;
    }

    // transfers an NFT owned by contract back to the sender
    function withdrawNft(address nftAddress, uint256 tokenId) external isOwner {
        ERC721(nftAddress).transferFrom(this, msg.sender, tokenId);
    }

    function withdrawProfits() external isOwner {

        if (jackpot > address(this).balance) {
            revert("not enough MATIC to pay jackpot winner!");
        } else {
            (bool success, ) = payable(msg.sender).call{
                value: (address(this).balance - jackpot)
            }("");
            require(success);
        }
    }

    function withdraw_all_native_token() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function withdrawLink() public {
       ERC20(__linkTokenAddress).transfer(owner, ERC20(__linkTokenAddress).balanceOf(address(this)));
    }
}