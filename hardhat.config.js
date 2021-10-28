require("@nomiclabs/hardhat-web3");
require("@nomiclabs/hardhat-truffle5");
require("@nomiclabs/hardhat-etherscan");
require('dotenv').config()
require("solidity-coverage");

const NO_PRIVATE = "0x0000000000000000000000000000000000000000000000000000000000000000";

const PRIVATE_KEY = process.env.PRIVATE_KEY || NO_PRIVATE;

const EXPLORER_API_KEY = process.env.EXPLORER_API_KEY || "";

const AVALANCHE_RPC_URL = process.env.AVALANCHE_RPC_URL || "";
const AVALANCHE_TEST_RPC_URL = process.env.AVALANCHE_TEST_RPC_URL || "";
const BSC_RPC_URL = process.env.BSC_RPC_URL || "";
const BSC_TEST_RPC_URL = process.env.BSC_TEST_RPC_URL || "";

const getEnv = env => {
  const value = process.env[env];
  if (typeof value === 'undefined') {
    console.log(`${env} has not been set.`);
    return "";
  }
  return value;
};

task("accounts", "Prints accounts", async (_, { web3 }) => {
  console.log(await web3.eth.getAccounts());
});

module.exports = {
  // defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      hardfork: "istanbul"
    },
    bsc: {
      url: BSC_RPC_URL,
      accounts: [PRIVATE_KEY]
    },
    bscTest: {
      url: BSC_TEST_RPC_URL,
      accounts: [PRIVATE_KEY]
    },
    avax: {
      url: AVALANCHE_RPC_URL,
      accounts: [PRIVATE_KEY]
    },
    avaxTest: {
      url: AVALANCHE_TEST_RPC_URL,
      accounts: [PRIVATE_KEY]
    }
  },
  solidity: {
    version: "0.6.12",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      },
      evmVersion: "istanbul"
    }
  },
  etherscan: {
    apiKey: EXPLORER_API_KEY
  },
};
