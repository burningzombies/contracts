import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";

dotenv.config();

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

task("lottery", "Manage lottery", async (taskArgs: any, hre) => {
  try {
    const [owner] = await hre.ethers.getSigners();
    const lottery = await hre.ethers.getContractAt(
      "OneLottery",
      taskArgs.contract
    );

    switch (taskArgs.cmd) {
      case "start": {
        await lottery
          .connect(owner)
          .start({ value: hre.ethers.utils.parseUnits("1", 18) });
        process.exit(0); // eslint-disable-line no-process-exit
      }
      case "finalize": {
        await lottery
          .connect(owner)
          .finalize(Math.floor(Math.random() * new Date().getTime()));
        process.exit(0); // eslint-disable-line no-process-exit
      }
      default: {
        throw new Error("No arg.");
      }
    }
  } catch (err: any) {
    console.log(err.stack);
    process.exit(1); // eslint-disable-line no-process-exit
  }
})
  .addPositionalParam("cmd")
  .addParam("contract", "Contract Address");

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.0",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  networks: {
    fuji: {
      url: "https://api.avax-test.network/ext/bc/C/rpc",
      chainId: 43113,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    mainnet: {
      url: "https://api.avax.network/ext/bc/C/rpc",
      chainId: 43114,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.SNOWTRACE_API_KEY,
  },
  mocha: {
    timeout: 99999999,
  },
};

export default config;
