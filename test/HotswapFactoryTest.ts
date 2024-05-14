import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { ContractTransactionResponse } from "ethers";
import { ethers } from "hardhat";
import { HotswapController, HotswapLiquidity } from "../typechain-types";
import { expect } from "chai";

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

describe("HotswapFactory", function () {
  async function deploy() {
    const [owner] = await ethers.getSigners();
    const HotswapFactory = await ethers.getContractFactory("HotswapFactory");
    const HotswapController = await ethers.getContractFactory("HotswapController");
    const HotswapLiquidity = await ethers.getContractFactory("HotswapLiquidity");

    const factory = await HotswapFactory.deploy();
    const mockNFT = await (await ethers.getContractFactory("MockNFT")).deploy()
    const mockFFT = await (await ethers.getContractFactory("MockERC20")).deploy()

    ethers.provider.send("hardhat_setBalance", [
      await owner.getAddress(),
      "0x10000000000000000000000000000000000000000",
    ]);

    await mockNFT.mint(owner);

    const tx = await factory.deployHotswap(await mockNFT.getAddress(), await mockFFT.getAddress(), {
      value: BigInt(DEPLOY_FEE)
    });



    const [controllerAddr, liquidityAddr] = await extractDeployEvent(tx);

    const controller = await HotswapController.attach(controllerAddr) as HotswapController;
    const liquidity = await HotswapLiquidity.attach(liquidityAddr) as HotswapLiquidity;





    return { mockNFT, mockFFT, factory, controller, liquidity }
  }

  describe("Basic Functionality", async () => {
    it("deployHotswap should not fail", async () => {
      const { factory, mockFFT, mockNFT } = await loadFixture(deploy);
      const [owner] = await ethers.getSigners();

      ethers.provider.send("hardhat_setBalance", [
        await owner.getAddress(),
        "0x10000000000000000000000000000000000000000",
      ]);

      const tx = await factory.deployHotswap(await mockFFT.getAddress(), await mockNFT.getAddress(), {
        value: BigInt(DEPLOY_FEE)
      });

      let controllerAddr = "";
      let liquidityAddr = "";

      const rcpt = await tx.wait()
      for (const log of rcpt?.logs ?? []) {
        if ("fragment" in log) {
          if (log.fragment.name == "HotswapDeployed") {
            controllerAddr = log.args[0];
            liquidityAddr = log.args[1];
          }

          console.log(`${log.fragment.name} => ${log.args}`);
        } else {
          //console.log(log);
        }
      }
    });

    it("should successfully deposit NFT", async () => {
      const { factory, mockFFT, mockNFT, controller, liquidity } = await loadFixture(deploy);
      const [owner] = await ethers.getSigners();

      await controller.depositNFT(1);

      expect(await mockNFT.ownerOf(1)).to.eq(await liquidity.getAddress(), "Liquidity does not own the NFT");
    });
  });
});

