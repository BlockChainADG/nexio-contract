require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
const priKey = process.env.PRI_KEY;
const bscApiKey = process.env.BSCSCAN_API_KEY;
const nodeUrl = process.env.NODE_URL;
const ankr_key = process.env.ANKR_KEY;
module.exports = {
  solidity: {
    version: "0.8.28",
    settings:{
      optimizer: { enabled: true, runs: 200 },
      viaIR: true
    }
  },
  networks: {
    hardhat: {
      chainId: 1337, // 明确指定 chainId
    },
    bsc_test: {
      url: `https://rpc.ankr.com/bsc_testnet_chapel/`+ ankr_key,
      accounts: [priKey]
    },
    bsc:{
      url: nodeUrl,
      accounts: [priKey]
    },
    polygon: {
      url: `https://rpc.ankr.com/polygon/` + ankr_key,
      accounts: [priKey]
    },
  },
  etherscan: {
    apiKey: bscApiKey,
  },
};
