pragma solidity ^0.4.21;

import "zeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Token.sol";

/**
 * @title CryptoPuff
 * CryptoPuff - a contract for my non-fungible crypto puffs.
 */
contract TokenFactory {

    event TokenCreated(address _address, string _name, string _symbol);

    mapping ( address => address ) contracts;

    function createToken(string _name, string _symbol) public { 
        contracts[msg.sender] = new Token(_name, _symbol);
        emit TokenCreated(contracts[msg.sender], _name, _symbol);
    }

}
