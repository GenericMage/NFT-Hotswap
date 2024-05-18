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

    await tendies.set("Testnet Tendies", "TT", BigInt(1000e18));
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

  describe("Basic Functionality", async () => {
    it("deployHotswap should not fail", async () => {
      const { factory, tendies, mockNFT } = await loadFixture(deploy);
      const [owner] = await ethers.getSigners();

      ethers.provider.send("hardhat_setBalance", [
        await owner.getAddress(),
        "0x10000000000000000000000000000000000000000",
      ]);

      const tx = await factory.deployHotswap(await tendies.getAddress(), await mockNFT.getAddress(), {
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

      const liqAddr = await liquidity.getAddress();

      await controller.depositNFT(2);
      await expect(mockNFT.tokenOfOwnerByIndex(liqAddr, 0)).not.be.reverted;
      await expect(mockNFT.tokenOfOwnerByIndex(liqAddr, 1)).not.be.reverted;
    });

    it("should successfully swap FFTs", async () => {
      const [owner] = await ethers.getSigners();
      const { factory, tendies, mockNFT, controller, liquidity } = await loadFixture(deploy);

      const controllerAddr = controller.getAddress();
      await tendies.increaseAllowance(controllerAddr, BigInt(1000e18));
      await mockNFT.setApprovalForAll(controllerAddr, true);

      await controller.depositNFT(2);
      await controller.depositFFT(BigInt(900e18));

      await controller.updatePrice();
      await expect(controller.swapFFT(BigInt(500e18))).to.not.reverted;

      console.log(await controller.queryLiquid(0));
      await expect(controller.withdrawLiquidity(0)).to.not.reverted;
      console.log(await controller.queryLiquid(0));

      await expect(controller.queryLiquid(1)).to.be.reverted;
      await expect(controller.claimFees()).to.not.reverted;
    });

    it("should successfully swap NFTs", async () => {
      const [owner] = await ethers.getSigners();
      const { factory, tendies, mockNFT, controller, liquidity } = await loadFixture(deploy);

      const controllerAddr = controller.getAddress();
      await tendies.increaseAllowance(controllerAddr, BigInt(1000e18));
      await mockNFT.setApprovalForAll(controllerAddr, true);

      await controller.depositNFT(3);
      await controller.depositFFT(BigInt(900e18));

      await controller.updatePrice();


      // console.log("Before swap\n------------------");
      // console.log(); console.log();
      // console.log(await controller.decimals())
      // console.log(await tendies.decimals())
      // console.log(await controller.queryLiquid(0));
      // console.log(await controller.queryLiquid(1));
      // console.log(await controller._price());


      // console.log("After swap\n------------------");
      // console.log(); console.log();
      // await controller.swapNFT(2)
      await expect(controller.swapNFT(2)).not.reverted;

      // console.log(await controller.queryLiquid(0));
      // console.log(await controller.queryLiquid(1));
      // console.log(await controller._price());
    });

  });
});

