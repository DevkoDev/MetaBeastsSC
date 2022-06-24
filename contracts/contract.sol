// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract MetaBeasts is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {
    uint256[] public _IdsLeft;
    mapping(uint256 => uint256) public _Limits;
    mapping(uint256 => uint256) public _Mints;
    uint256 public _Nonce;
    using Counters for Counters.Counter;
    using ECDSA for bytes32;
    using Strings for uint256;
    uint256 public MB_TEAM_RESERVE = 1000;
    uint256 public MB_PUBLIC = 3000;
    uint256 public MB_PRIVATE = 1000;
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
    address public teamWallet = 0x2007261e1c354C71cC1FC9597871D5F898339126; // should be a multi signature wallet address

    constructor() ERC1155("https://gateway.pinata.cloud/ipfs/QmZMWmqX9jatszvV5PoViFzsg77fNuUHo3KkQSBCruEVfT/{id}.json") {
        for (uint256 index = 1; index <= 100; index++) {
            _IdsLeft.push(index);
        }
        for (uint256 index = 1; index <= 38; index++) {
            _Limits[index] = 131;
        }
        for (uint256 index = 39; index <= 65; index++) {
            _Limits[index] = 104;
        }
        for (uint256 index = 66; index <= 85; index++) {
            _Limits[index] = 75;
        }
        for (uint256 index = 86; index <= 95; index++) {
            _Limits[index] = 60;
        }
        for (uint256 index = 96; index <= 99; index++) {
            _Limits[index] = 26;
        }
        _Limits[100] = 10;
    }

    modifier onlyTeam() {
        require(msg.sender == teamWallet, "NOT_ALLOWED");
        _;
    }

    modifier notContract() {
        require((!_isContract(msg.sender)) && (msg.sender == tx.origin), "contract not allowed");
        _;
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
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

    function setURI(string memory newuri) public onlyTeam {
        _setURI(newuri);
    }

    function gift(address[] calldata receivers) external onlyTeam {
        require(
            teamChestsMinted + (receivers.length / 2) <= MB_TEAM_RESERVE,
            "EXCEED_TEAM_RESERVE"
        );
        require(receivers.length % 2 == 0, "NOT_EVEN");
        teamChestsMinted = teamChestsMinted + (receivers.length / 2);
        for (uint256 i = 0; i < receivers.length; i++) {
            mintRandom(receivers[i], 1);
        }
    }

    function founderMint(uint256 tokenQuantity) external onlyTeam {
        require(
            teamChestsMinted + (tokenQuantity / 2) <= MB_TEAM_RESERVE,
            "EXCEED_TEAM_RESERVE"
        );
        require(tokenQuantity % 2 == 0, "NOT_EVEN");
        teamChestsMinted = teamChestsMinted + (tokenQuantity / 2);
        mintRandom(msg.sender, tokenQuantity);
    }

    function giftChest(address[] calldata receivers) external onlyTeam {
        require(
            teamChestsMinted + receivers.length <= MB_TEAM_RESERVE,
            "EXCEED_TEAM_RESERVE"
        );
        teamChestsMinted = teamChestsMinted + receivers.length;
        for (uint256 i = 0; i < receivers.length; i++) {
            _mint(receivers[i], 0, 1, "");
        }
    }

    function founderMintChest(uint256 tokenQuantity) external onlyTeam {
        require(
            teamChestsMinted + tokenQuantity <= MB_TEAM_RESERVE,
            "EXCEED_TEAM_RESERVE"
        );
        teamChestsMinted = teamChestsMinted + tokenQuantity;
        _mint(msg.sender, 0, tokenQuantity, "");
    }

    function buyAndOpenChests(uint256 quantity) external payable notContract {
        require(publicLive, "MINT_CLOSED");
        require(publicChestsMinted + quantity <= MB_PUBLIC, "EXCEED_PUBLIC");
        require(quantity <= MB_PER_MINT, "EXCEED_PER_MINT");
        require(MB_PRICE * quantity <= msg.value, "INSUFFICIENT_ETH");

        publicChestsMinted = publicChestsMinted + quantity;
        mintRandom(msg.sender, quantity * 2);
    }

    function privateBuy(uint256 quantity, bytes memory signature)
        external
        payable
        notContract
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
        notContract
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
        mintRandom(msg.sender, quantity * 2);
    }

    function buyChests(uint256 quantity) external payable notContract {
        require(publicLive, "MINT_CLOSED");
        require(publicChestsMinted + quantity <= MB_PUBLIC, "EXCEED_PUBLIC");
        require(quantity <= MB_PER_MINT, "EXCEED_PER_MINT");
        require(MB_PRICE * quantity <= msg.value, "INSUFFICIENT_ETH");

        publicChestsMinted = publicChestsMinted + quantity;
        _mint(msg.sender, 0, quantity, "");
    }

    function mintRandom(address to, uint256 quantity) private {
        require(_IdsLeft.length > 0, "NO_TOKEN_LEFT");
        require(quantity > 0, "NOT_ALLOWED");
        for (uint256 index = 0; index < quantity; index++) {
            uint256 randomIndex = uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number),
                        blockhash(block.number - 100),
                        block.coinbase,
                        block.timestamp,
                        block.number,
                        _Nonce
                    )
                )
            ) % (_IdsLeft.length);

            uint256 randomTokenId = _IdsLeft[randomIndex];
            _Mints[randomTokenId]++;
            _Nonce++;
            if (_Mints[randomTokenId] == _Limits[randomTokenId]) {
                _IdsLeft[randomIndex] = _IdsLeft[_IdsLeft.length - 1];
                _IdsLeft.pop();
            }
            _mint(to, randomTokenId, 1, "");
        }
    }

    function openChests(uint256 quantity) external notContract {
        require(
            this.balanceOf(msg.sender, 0) >= quantity,
            "INSUFFICIENT_CHESTS"
        );
        _burn(msg.sender, 0, quantity);
        mintRandom(msg.sender, quantity * 2);
    }

    function forge(uint256 tokenId) external notContract {
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
    

    function getOwnedCards(address addressToCheck) public view returns (uint256[300] memory){
        uint256[300] memory cardsOwned;
        for (uint256 index = 0; index < 300; index++) {
            cardsOwned[index] = balanceOf(addressToCheck, index + 1);
        }
        return cardsOwned;
    }
    
    function getMintedCards() public view returns (uint256[300] memory){
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

    function togglePublicMintStatus() external onlyTeam {
        publicLive = !publicLive;
    }

    function togglePrivateStatus() external onlyTeam {
        privateLive = !privateLive;
    }

    function setPrivate(uint256 newCount) external onlyTeam {
        MB_PRIVATE = newCount;
    }

    function setTeamReserve(uint256 newCount) external onlyTeam {
        MB_TEAM_RESERVE = newCount;
    }

    function setPublicReserve(uint256 newCount) external onlyTeam {
        MB_PUBLIC = newCount;
    }

    function setNewTeamWallet(address newAddress) external onlyTeam {
        teamWallet = newAddress;
    }
    
    function withdraw() external onlyTeam {
        uint256 currentBalance = address(this).balance;
        Address.sendValue(payable(0x11111F01570EeAA3e5a2Fd51f4A2f127661B9834), currentBalance * 4 / 100);
        Address.sendValue(payable(0x44e01D3d375d27fbb9b32228D9A346cA15aE0b63), address(this).balance);
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
