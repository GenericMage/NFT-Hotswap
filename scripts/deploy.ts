import { deployContract } from "@nomicfoundation/hardhat-ethers/types";
import "@nomicfoundation/hardhat-verify";
import { configDotenv } from "dotenv";
import { ContractTransaction, ContractTransactionReceipt, ContractTransactionResponse, ZeroAddress } from "ethers";
import { ethers, run, network } from "hardhat";

require('hardhat-ethernal');
const hre = require("hardhat");

async function extractDeployEvent(tx: ContractTransactionResponse) {
  const rcpt = await tx.wait();
  let controllerAddr = "";
  let liquidityAddr = "";

  for (const log of rcpt?.logs ?? []) {
    if ("fragment" in log) {
      if (log.fragment.name == "HotswapDeployed") {
        controllerAddr = log.args[0];
        liquidityAddr = log.args[1];
        break;
      }

      // console.log(`${log.fragment.name} => ${log.args}`);
    }
  }

  return [controllerAddr, liquidityAddr];
}

async function deployFactory() {
  try {
    const factory = await ethers.deployContract("HotswapFactory");

    return factory;
  } catch (err) {
    console.log("Deploy failed", err)
    throw err;
  }
}

async function keepTrying(action: () => Promise<unknown>, delay = 3000) {
  let cb: ((value?: unknown) => void) = () => { };

  while (true) {
    try {
      await action();
      break;
    } catch (err) {
      console.error(err);


      const promise = new Promise((resolve) => cb = resolve);
      setTimeout(() => {
        cb();
      }, delay)
      await promise;
    }
  }
}

async function main() {
  configDotenv();

  const feeData = await ethers.provider.getFeeData();
  console.log("Fee Data", feeData);

  const factory = await ethers.deployContract("HotswapFactory");

  const controllerFactory = await ethers.getContractFactory("HotswapController");
  const legacyController = await controllerFactory.deploy(ZeroAddress, ZeroAddress);

  const liquidityFactory = await ethers.getContractFactory("HotswapLiquidity");
  const legacyLiquidity = await liquidityFactory.deploy(ZeroAddress, ZeroAddress);


  await factory.deploymentTransaction();

  const factoryAddr = await factory.getAddress();

  const controller = await legacyController.getAddress();
  const liquidity = await legacyLiquidity.getAddress();




  console.log("Deployment successful!");
  console.log(`HotswapFactory: ${factoryAddr}`);
  console.log(`HotswapLegacyController: ${controller}`);
  console.log(`HotswapLegacyLiquidity: ${liquidity}`);
  console.log(); console.log();

  if (network.name != "localhost") {
    await keepTrying(() => {
      return run("verify:verify", {
        address: factoryAddr
      });
    });

    await keepTrying(() => {
      return run("verify:verify", {
        address: controller,
        constructorArguments: [ZeroAddress, ZeroAddress]
      });
    });

    await keepTrying(() => {
      return run("verify:verify", {
        address: liquidity,
        constructorArguments: [ZeroAddress, ZeroAddress]
      });
    });


  } else {
    hre.ethernal.push({
      name: "HotswapFactory",
      address: factoryAddr
    })
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
