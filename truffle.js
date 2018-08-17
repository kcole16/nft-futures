module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*",
      gas: 4612388
    },
    ganache: {
      host: "localhost",
      port: 7545,
      network_id: "*",
      gas: 4612388
    }
  }
};
