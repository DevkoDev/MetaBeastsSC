// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";


contract MetaBeasts is
    ERC1155,
    Ownable,
    ERC1155Burnable,
    ERC1155Supply
{

    mapping(uint256 => uint256) public _Limits;
    mapping(uint256 => uint256) public _Mints;
    uint256 public _Nonce;


    using Counters for Counters.Counter;
    using ECDSA for bytes32;
    using Strings for uint256;

    uint256 public MB_TEAM_RESERVE = 1800;
    uint256 public MB_PUBLIC = 6000;
    uint256 public MB_PRIVATE = 2200;
    uint256 public MB_MAX = MB_TEAM_RESERVE + MB_PUBLIC + MB_PRIVATE;
    uint256 public MB_PRICE = 0.1 ether;
    uint256 public MB_PER_WALLET = 5;
    uint256 public MB_PER_MINT = 5;
    mapping(address => uint256) public P_MINTERS;

    address private PRIVATE_SIGNER = 0xd7E75d41594986a2bcd545196feDEfc3123Fd336;
    string private constant MB_SIG_WORD = "MetaBeasts_PRIVATE";

    uint256 public publicChestsMinted;
    uint256 public privateChestsMinted;
    uint256 public teamChestsMinted;

    bool public privateLive;
    bool public publicLive;
    struct request {
        bool prepared;
        address owner;
    }
    mapping(uint256 => request) public openChest_requests;

    constructor()
        ERC1155(
            "https://gateway.pinata.cloud/ipfs/QmZMWmqX9jatszvV5PoViFzsg77fNuUHo3KkQSBCruEVfT/{id}.json"
        )
    {
        for (uint256 index = 1; index <= 38; index++) {
            _Limits[index] = 263;
        }
        for (uint256 index = 39; index <= 65; index++) {
            _Limits[index] = 207;
        }
        for (uint256 index = 66; index <= 85; index++) {
            _Limits[index] = 150;
        }
        for (uint256 index = 86; index <= 95; index++) {
            _Limits[index] = 118;
        }
        for (uint256 index = 96; index <= 99; index++) {
            _Limits[index] = 54;
        }
        _Limits[100] = 21;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function prepareChests(uint256 quantity) external callerIsUser {
        require(this.balanceOf(msg.sender, 0) >= quantity, "INSUFFICIENT_CHESTS");
        _burn(msg.sender, 0, quantity);
        for (uint256 index = 1; index <= quantity; index++) {
            openChest_requests[_Nonce + index].prepared = true;
            openChest_requests[_Nonce + index].owner = msg.sender;
        }
        _Nonce += quantity;
    }

    function openChest(
        uint256 requestId,
        bytes memory signature,
        uint256 tokenId
    ) external {
        require(openChest_requests[requestId].prepared, "INVALID_REQUEST");
        require(openChest_requests[requestId].owner == msg.sender, "NOT_OWNER");
        require(_Mints[tokenId] < _Limits[tokenId], "LIMIT_REACHED");
        require(tokenId <= 100, "INVALID_TOKEN");
        require(tokenId != 0, "INVALID_TOKEN");
        require(matchSignerTokenId(signature, tokenId), "INVALID_SIGNATURE");

        openChest_requests[requestId].prepared = false;
        _Mints[tokenId]++;
        _mint(msg.sender, tokenId, 1, "");
    }

    function matchSignerTokenId(bytes memory signature, uint256 tokenId)
        private
        view
        returns (bool)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(msg.sender, MB_SIG_WORD, tokenId))
            )
        );
        return PRIVATE_SIGNER == hash.recover(signature);
    }

    function matchAddresSigner(bytes memory signature)
        private
        view
        returns (bool)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(msg.sender, MB_SIG_WORD))
            )
        );
        return PRIVATE_SIGNER == hash.recover(signature);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function gift(address[] calldata receivers, uint256 requestIdStart) external onlyOwner {
        require(
            teamChestsMinted + (receivers.length / 2) <= MB_TEAM_RESERVE,
            "EXCEED_TEAM_RESERVE"
        );
        require(receivers.length % 2 == 0, "NOT_EVEN");
        teamChestsMinted = teamChestsMinted + (receivers.length / 2);
        for (uint256 i = 0; i < receivers.length; i++) {
            this.prepareChests(receivers[i], 1);
        }
    }

    function founderMint(uint256 tokenQuantity) external onlyOwner {
        require(
            teamChestsMinted + (tokenQuantity / 2) <= MB_TEAM_RESERVE,
            "EXCEED_TEAM_RESERVE"
        );
        require(tokenQuantity % 2 == 0, "NOT_EVEN");
        teamChestsMinted = teamChestsMinted + (tokenQuantity / 2);
       // mintRandom(msg.sender, tokenQuantity);
    }

    function giftChest(address[] calldata receivers) external onlyOwner {
        require(
            teamChestsMinted + receivers.length <= MB_TEAM_RESERVE,
            "EXCEED_TEAM_RESERVE"
        );
        teamChestsMinted = teamChestsMinted + receivers.length;
        for (uint256 i = 0; i < receivers.length; i++) {
            _mint(receivers[i], 0, 1, "");
        }
    }

    function founderMintChest(uint256 tokenQuantity) external onlyOwner {
        require(
            teamChestsMinted + tokenQuantity <= MB_TEAM_RESERVE,
            "EXCEED_TEAM_RESERVE"
        );
        teamChestsMinted = teamChestsMinted + tokenQuantity;
        _mint(msg.sender, 0, tokenQuantity, "");
    }

    function buyAndOpenChests(uint256 quantity) external payable callerIsUser {
        require(publicLive, "MINT_CLOSED");
        require(publicChestsMinted + quantity <= MB_PUBLIC, "EXCEED_PUBLIC");
        require(quantity <= MB_PER_MINT, "EXCEED_PER_MINT");
        require(MB_PRICE * quantity <= msg.value, "INSUFFICIENT_ETH");

        publicChestsMinted = publicChestsMinted + quantity;
       // mintRandom(msg.sender, quantity * 2);
    }

    function privateBuy(uint256 quantity, bytes memory signature)
        external
        payable
        callerIsUser
    {
        require(privateLive, "MINT_CLOSED");
        require(privateChestsMinted + quantity <= MB_PRIVATE, "EXCEED_PRIVATE");
        require(
            P_MINTERS[msg.sender] + quantity <= MB_PER_WALLET,
            "EXCEED_PER_WALLET"
        );
        require(matchAddresSigner(signature), "DIRECT_MINT_DISALLOWED");
        require(MB_PRICE * quantity <= msg.value, "INSUFFICIENT_ETH");
        P_MINTERS[msg.sender] = P_MINTERS[msg.sender] + quantity;
        privateChestsMinted = privateChestsMinted + quantity;
        _mint(msg.sender, 0, quantity, "");
    }

    function privateBuyAndOpenChest(uint256 quantity, bytes memory signature)
        external
        payable
        callerIsUser
    {
        require(privateLive, "MINT_CLOSED");
        require(privateChestsMinted + quantity <= MB_PRIVATE, "EXCEED_PRIVATE");
        require(
            P_MINTERS[msg.sender] + quantity <= MB_PER_WALLET,
            "EXCEED_PER_WALLET"
        );
        require(matchAddresSigner(signature), "DIRECT_MINT_DISALLOWED");
        require(MB_PRICE * quantity <= msg.value, "INSUFFICIENT_ETH");
        P_MINTERS[msg.sender] = P_MINTERS[msg.sender] + quantity;
        privateChestsMinted = privateChestsMinted + quantity;
     //   mintRandom(msg.sender, quantity * 2);
    }

    function buyChests(uint256 quantity) external payable callerIsUser {
        require(publicLive, "MINT_CLOSED");
        require(publicChestsMinted + quantity <= MB_PUBLIC, "EXCEED_PUBLIC");
        require(quantity <= MB_PER_MINT, "EXCEED_PER_MINT");
        require(MB_PRICE * quantity <= msg.value, "INSUFFICIENT_ETH");

        publicChestsMinted = publicChestsMinted + quantity;
        _mint(msg.sender, 0, quantity, "");
    }

    function forge(uint256 tokenId) external callerIsUser {
        require(tokenId > 0, "INVALID_ID");
        require(tokenId <= 200, "INVALID_ID");
        require(this.balanceOf(msg.sender, tokenId) >= 2, "INSUFFICIENT_CARDS");
        _burn(msg.sender, tokenId, 2);
        _mint(msg.sender, tokenId + 100, 1, "");
    }







    function totalBalanceOf(address addressToCheck)
        public
        view
        returns (uint256)
    {
        uint256 total = 0;
        for (uint256 index = 1; index <= 300; index++) {
            total = total + balanceOf(addressToCheck, index);
        }
        return total;
    }

    function getOwnedCards(address addressToCheck)
        public
        view
        returns (uint256[300] memory)
    {
        uint256[300] memory cardsOwned;
        for (uint256 index = 0; index < 300; index++) {
            cardsOwned[index] = balanceOf(addressToCheck, index + 1);
        }
        return cardsOwned;
    }

    function getMintedCards() public view returns (uint256[300] memory) {
        uint256[300] memory cardsOwned;
        for (uint256 index = 0; index < 300; index++) {
            cardsOwned[index] = totalSupply(index + 1);
        }
        return cardsOwned;
    }

    function totalCardsSupply() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 index = 1; index <= 300; index++) {
            total = total + totalSupply(index);
        }
        return total;
    }

    function totalChestsSupply() public view returns (uint256) {
        return totalSupply(0);
    }

    function totalTier1Supply() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 index = 1; index <= 100; index++) {
            total = total + totalSupply(index);
        }
        return total;
    }

    function totalTier2Supply() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 index = 101; index <= 200; index++) {
            total = total + totalSupply(index);
        }
        return total;
    }

    function totalTier3Supply() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 index = 201; index <= 300; index++) {
            total = total + totalSupply(index);
        }
        return total;
    }

    function togglePublicMintStatus() external onlyOwner {
        publicLive = !publicLive;
    }

    function togglePrivateStatus() external onlyOwner {
        privateLive = !privateLive;
    }

    function setPrivate(uint256 newCount) external onlyOwner {
        MB_PRIVATE = newCount;
    }

    function setTeamReserve(uint256 newCount) external onlyOwner {
        MB_TEAM_RESERVE = newCount;
    }

    function setPublicReserve(uint256 newCount) external onlyOwner {
        MB_PUBLIC = newCount;
    }

    // WIP
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
