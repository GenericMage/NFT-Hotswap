import { ethers } from "hardhat";
import { HotswapController, HotswapLiquidity } from "../typechain-types";
import { ContractTransactionResponse } from "ethers";

const DEPLOY_FEE = 1e15;

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

export async function classicDeploy() {
  const [owner] = await ethers.getSigners();
  const HotswapFactory = await ethers.getContractFactory("HotswapFactory");
  const HotswapController = await ethers.getContractFactory("HotswapController");
  const HotswapLiquidity = await ethers.getContractFactory("HotswapLiquidity");

  const factory = await HotswapFactory.deploy();
  const mockNFT = await (await ethers.getContractFactory("MockNonFunLady")).deploy()
  const mockFFT = await (await ethers.getContractFactory("MockERC20")).deploy()
  const tendies = await (await ethers.getContractFactory("TestnetTendies")).deploy()

  ethers.provider.send("hardhat_setBalance", [
    await owner.getAddress(),
    "0x10000000000000000000000000000000000000000",
  ]);

  await mockNFT.flipSaleState();

  await mockNFT.mintLady(30, {
    value: 1000000000000000
  });

  await tendies.set("Testnet Tendies", "TT", BigInt(10000e18));
  await tendies.mint();



  // await mockNFT.mint(owner);

  const tx = await factory.deployHotswap(await mockNFT.getAddress(), await tendies.getAddress(), {
    value: BigInt(DEPLOY_FEE)
  });



  const [controllerAddr, liquidityAddr] = await extractDeployEvent(tx);

  const controller = await HotswapController.attach(controllerAddr) as HotswapController;
  const liquidity = await HotswapLiquidity.attach(liquidityAddr) as HotswapLiquidity;

  console.log(`\n\nController: ${controllerAddr}\nLiquidity: ${liquidityAddr}`);
  console.log(); console.log();


  await mockNFT.setApprovalForAll(controllerAddr, true);


  return { mockNFT, mockFFT, tendies, factory, controller, liquidity }
}

export async function outputLogs(act: Promise<ContractTransactionResponse>) {
  const tx = await act;
  const rcpt = await tx.wait()

  for (const log of rcpt?.logs ?? []) {
    if ("fragment" in log) {
      console.log(`${log.fragment.name} => ${log.args}`);
    }
  }
};