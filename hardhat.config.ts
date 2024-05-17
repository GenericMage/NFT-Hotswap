import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import { configDotenv } from "dotenv";
require("hardhat-contract-sizer");

configDotenv();

// TODO: API keys leaked. Changed during production
const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.25",

        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
            details: { yul: false },
          },
        }

      },
      {
        version: "0.7.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
            details: { yul: false },
          },
        }
      },
    ],
  },
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
    //only: [':ERC20$'],
  },

  //"0.8.25",
  etherscan: {
    apiKey: process.env.FTM_API_KEY as string
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
    avax_testnet: {
      url: "https://api.avax-test.network/ext/bc/C/rpc",
      chainId: 43113,
      accounts: [process.env.PRIVATE_KEY as string],
    }
  }
};

export default config;
