import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import { configDotenv } from "dotenv";
import { boolean } from "hardhat/internal/core/params/argumentTypes";
// require("hardhat-contract-sizer");
require('hardhat-ethernal');

configDotenv();

const optimizerSettings = {
  optimizer: {
    enabled: true,
    runs: 200,
    details: { yul: false },
  },
}

interface HardhatContractSizerConfig {
  contractSizer: {
    alphaSort?: boolean,
    disambiguatePaths?: boolean,
    runOnCompile?: boolean,
    strict?: boolean,
    only?: string[],
  }
}

// TODO: API keys leaked. Changed during production
const config: HardhatUserConfig & Partial<HardhatContractSizerConfig> = {
  solidity: {
    compilers: [
      {
        version: "0.8.25",
        settings: {
          ...optimizerSettings
        }
      },
      {
        version: "0.8.0",
        settings: {
          ...optimizerSettings
        }
      },
      {
        version: "0.7.0",
        settings: {
          ...optimizerSettings
        }
      },
    ],
  },
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
  },

  //"0.8.25",
  etherscan: {
    apiKey: process.env.POLY_API_KEY as string
    // apiKey: process.env.SNOWTRACE_API_KEY as string
  },
  networks: {
    // local: {
    //   url: 'http://127.0.0.1:8545/',
    //   gasPrice: 225000000000,
    //   chainId: 43112,
    //   accounts: [
    //     "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
    //     "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d",
    //     "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"
    //   ]
    // },
    // hardhat: {
    //   allowUnlimitedContractSize: true
    // },
    ftm_testnet: {
      url: "https://rpc.testnet.fantom.network",
      chainId: 4002,
      accounts: [process.env.PRIVATE_KEY as string],
    },
    poly_mainnet: {
      url: "https://polygon-rpc.com/",
      chainId: 137,
      accounts: [process.env.PRIVATE_KEY as string],
    },
    avax_testnet: {
      url: "https://api.avax-test.network/ext/bc/C/rpc",
      chainId: 43113,
      accounts: [process.env.PRIVATE_KEY as string],
    }
  }
};

export default config;
