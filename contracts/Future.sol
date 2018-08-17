pragma solidity ^0.4.21;

import "zeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "zeppelin-solidity/contracts/token/ERC721/ERC721Holder.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

/**
 * @title CryptoPuff
 * CryptoPuff - a contract for my non-fungible crypto puffs.
 */
contract Future is ERC721Holder, Ownable {

    enum DealStates { INIT, IN_PROGRESS, MATURE, COMPLETE, EXPIRED }

    event DealInitiated(address _maker, address _token, uint _tokenId, uint _maturityDate, uint _expirationDate, uint _minDeposit, uint _price);

    struct Deal {
        address maker;
        address taker;
        address token;
        uint tokenId;
        uint maturityDate;
        uint expirationDate;
        uint minDeposit;
        uint price;
        bool assetDeposited;
        uint actualDeposit;
        DealStates state;
    }

    mapping (uint => Deal) idsToDeals;

    Deal[] public deals;

    mapping (address => Deal[]) dealsPerAddress;

    constructor() public { 
    }

    function initiateContract(address _token, uint _tokenId, uint _maturityDate, uint _expirationDate, uint _minDeposit, uint _price) {
        ERC721 token = ERC721(_token);
        token.safeTransferFrom(msg.sender, address(this), _tokenId);
        Deal memory deal = Deal(msg.sender, 0x0, _token, _tokenId, _maturityDate, _expirationDate, _minDeposit, _price, false, 0, DealStates.INIT); 
        uint dealId = deals.length;
        idsToDeals[dealId] = deal;
        deals.push(deal);
        deal.assetDeposited = true;
        dealsPerAddress[msg.sender].push(deal);
        emit DealInitiated(msg.sender, _token, _tokenId, _maturityDate, _expirationDate, _minDeposit, _price);
    }

    function takeContract(uint _dealId) public payable {
        Deal memory deal = idsToDeals[_dealId];
        require(msg.value >= deal.minDeposit);
        require(now <= deal.maturityDate);
        deal.actualDeposit = msg.value;
        deal.state = DealStates.IN_PROGRESS;
        deal.taker = msg.sender;
    }

}
