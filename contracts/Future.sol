pragma solidity ^0.4.21;

import "zeppelin-solidity/Deals/token/ERC721/ERC721.sol";
import "zeppelin-solidity/Deals/token/ERC721/ERC721Token.sol";
import "zeppelin-solidity/Deals/token/ERC721/ERC721Holder.sol";
import "zeppelin-solidity/Deals/ownership/Ownable.sol";


Deal Future is ERC721Token, ERC721Holder, Ownable {

    enum DealStates { INIT, IN_PROGRESS, COMPLETE, EXPIRED }

    event DealInitiated(address _maker, address _token, uint _tokenId, uint _maturityDate, uint _expirationDate, uint _minDeposit, uint _price);
    event DealTaken(address _taker, uint _dealId, uint _actualDeposit);
    event DealCompleted(address _taker, uint _dealId, uint _price);
    event DealClosed(address _maker, uint _dealId);

    struct Deal {
        address maker;
        address token;
        uint tokenId;
        uint maturityDate;
        uint expirationDate;
        uint minDeposit;
        uint price;
        uint dealId;
        bool assetDeposited;
        uint actualDeposit;
        DealStates state;
    }

    mapping (uint => Deal) idsToDeals;

    Deal[] public deals;

    mapping (address => Deal[]) dealsPerAddress;
    mapping (address => uint) balances;

    constructor() ERC721Token("FutureToken", "FUT") public { }

    function initiateDeal(address _token, uint _tokenId, uint _maturityDate, uint _expirationDate, uint _minDeposit, uint _price) {
        _transferToken(msg.sender, address(this), _token, _tokenId);
        Deal memory deal = Deal(msg.sender, _token, _tokenId, _maturityDate, _expirationDate, _minDeposit, _price, 0, false, 0, DealStates.INIT); 
        uint dealId = deals.length;
        idsToDeals[dealId] = deal;
        deal.dealId = dealId;
        deals.push(deal);
        deal.assetDeposited = true;
        dealsPerAddress[msg.sender].push(deal);
        emit DealInitiated(msg.sender, _token, _tokenId, _maturityDate, _expirationDate, _minDeposit, _price);
    }

    function takeDeal(uint _dealId) public payable {
        Deal memory deal = idsToDeals[_dealId];
        require(msg.value >= deal.minDeposit);
        require(now < deal.maturityDate);
        deal.actualDeposit = msg.value;
        deal.state = DealStates.IN_PROGRESS;
        _mintToken(deal.dealId);
        emit DealTaken(msg.sender, deal.dealId, msg.value);
    }

    function completeDeal(uint _dealId) public payable {
        Deal memory deal = idsToDeals[_dealId];
        require(msg.sender == ownerOf(deal.dealId));
        require(now >= deal.maturityDate);
        require((msg.value + deal.actualDeposit) == deal.price);
        _transferToken(address(this), msg.sender, deal.token, deal.tokenId);
        balances[deal.maker] += deal.price;
        deal.state = DealStates.COMPLETE;
        emit DealCompleted(msg.sender, deal.dealId, deal.price);
    }

    function closeDeal(uint _dealId) public {
        Deal memory deal = idsToDeals[_dealId];
        require(msg.sender == deal.maker);
        require(deal.state != DealStates.EXPIRED);
        if (deal.state != DealStates.INIT) {
            require(now >= deal.expirationDate);
        }
        _transferToken(address(this), msg.sender, deal.token, deal.tokenId);
        deal.state = DealStates.EXPIRED;
        balances[msg.sender] += deal.actualDeposit;
        withdraw();
        emit DealClosed(msg.sender, deal.dealId);
    }

    function withdraw() public {
        uint payment = balances[msg.sender];
        require(payment > 0);
        balances[msg.sender] -= payment;
        msg.sender.transfer(payment);
    }

    function _transferToken(address _from, address _to, address _token, uint _tokenId) internal {
        ERC721 token = ERC721(_token);
        token.transferFrom(_from, _to, _tokenId);
    }

    function _mintToken(uint _dealId) internal returns (uint){
        _mint(msg.sender, _dealId);
    }

    function _getNextTokenId() private view returns (uint256) {
        return totalSupply().add(1); 
    }

}
