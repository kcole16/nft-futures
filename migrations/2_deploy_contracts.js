var Token = artifacts.require("./Token.sol");
var TokenFactory = artifacts.require("./TokenFactory.sol");
var Future = artifacts.require("./Future.sol");

module.exports = function(deployer) {
  deployer.deploy(Token, 'Test', 'TES');
  deployer.deploy(TokenFactory);
  deployer.deploy(Future);
};
