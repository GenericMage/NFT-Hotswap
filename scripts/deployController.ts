import "@nomicfoundation/hardhat-verify";
import { configDotenv } from "dotenv";
import { ethers, run, network } from "hardhat";

async function main() {
  configDotenv();

  const contract = "contracts/HotswapController.sol:HotswapController";
  const controller = await ethers.deployContract(contract);
  const address = await controller.getAddress();

  console.log(`Successfully deployed to ${address}`);

  const tx = await controller.deploymentTransaction();
  await tx?.wait(6)

  await run("verify:verify", {
    address,
    contract
  })
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
