pragma solidity ^0.4.21;

import "zeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "zeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";
import "zeppelin-solidity/contracts/token/ERC721/ERC721Holder.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";


contract Future is ERC721Token, ERC721Holder, Ownable {

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
        uint contractId;
        bool assetDeposited;
        uint actualDeposit;
        DealStates state;
    }

    mapping (uint => Deal) idsToDeals;

    Deal[] public deals;

    mapping (address => Deal[]) dealsPerAddress;
    mapping (address => uint) balances;

    constructor() ERC721Token("FutureToken", "FUT") public { }

    function initiateContract(address _token, uint _tokenId, uint _maturityDate, uint _expirationDate, uint _minDeposit, uint _price) {
        _transferToken(msg.sender, address(this), _token, _tokenId);
        Deal memory deal = Deal(msg.sender, 0x0, _token, _tokenId, _maturityDate, _expirationDate, _minDeposit, _price, 0, false, 0, DealStates.INIT); 
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
        deal.contractId  = _mintTo();
    }

    function completeContract(uint _dealId) public payable {
        Deal memory deal = idsToDeals[_dealId];
        require(msg.sender == ownerOf(deal.contractId));
        require(now >= deal.maturityDate);
        require((msg.value + deal.actualDeposit) == deal.price);
        _transferToken(address(this), msg.sender, deal.token, deal.tokenId);
        balances[deal.maker] += deal.price;
        deal.state = DealStates.COMPLETE;
    }

    function closeContract(uint _dealId) public {
        Deal memory deal = idsToDeals[_dealId];
        require(msg.sender == deal.maker);
        require(now >= deal.expirationDate);
        require(deal.state != DealStates.EXPIRED);
        require((msg.value + deal.actualDeposit) == deal.price);
        _transferToken(address(this), msg.sender, deal.token, deal.tokenId);
        deal.state = DealStates.EXPIRED;
        balances[msg.sender] += deal.actualDeposit;
        withdraw();
    }

    function withdraw() public {
        uint payment = balances[msg.sender];
        require(payment > 0);
        balances[msg.sender] -= payment;
        msg.sender.transfer(payment);
    }

    function _transferToken(address _from, address _to, address _token, uint _tokenId) internal {
        ERC721 token = ERC721(_token);
        token.safeTransferFrom(_from, _to, _tokenId);
    }

    function _mintTo() internal returns (uint256){
        uint256 newTokenId = _getNextTokenId();
        _mint(msg.sender, newTokenId);
        return newTokenId;
    }

    function _getNextTokenId() private view returns (uint256) {
        return totalSupply().add(1); 
    }

}
