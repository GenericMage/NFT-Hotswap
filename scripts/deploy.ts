import { deployContract } from "@nomicfoundation/hardhat-ethers/types";
import "@nomicfoundation/hardhat-verify";
import { configDotenv } from "dotenv";
import { ContractTransaction, ContractTransactionReceipt, ContractTransactionResponse, ZeroAddress } from "ethers";
import { ethers, run, network } from "hardhat";

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

async function main() {
  configDotenv();

  const factory = await ethers.deployContract("HotswapFactory");

  const controllerFactory = await ethers.getContractFactory("HotswapController");
  const legacyController = await controllerFactory.deploy(ZeroAddress, ZeroAddress);

  const liquidityFactory = await ethers.getContractFactory("HotswapLiquidity");
  const legacyLiquidity = await liquidityFactory.deploy(ZeroAddress, ZeroAddress);

  // const legacyController

  await factory.deploymentTransaction();

  const factoryAddr = await factory.getAddress();

  const controller = await legacyController.getAddress();
  const liquidity = await legacyLiquidity.getAddress();




  console.log("Deployment successful!");
  console.log(`HotswapFactory: ${factoryAddr}`);
  console.log(`HotswapLegacyController: ${controller}`);
  console.log(`HotswapLegacyLiquidity: ${liquidity}`);

  if (network.name != "localhost") {
    await run("verify:verify", {
      address: factoryAddr
    })

    await run("verify:verify", {
      address: controller,
      constructorArguments: [ZeroAddress, ZeroAddress]
    })

    await run("verify:verify", {
      address: liquidity,
      constructorArguments: [ZeroAddress, ZeroAddress]
    })
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
