import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { ContractTransactionResponse } from "ethers";
import { ethers } from "hardhat";
import { HotswapController, HotswapLiquidity } from "../typechain-types";
import { expect } from "chai";
import { classicDeploy } from "./common";

const DEPLOY_FEE = 1e15;

describe("HotswapFactory", function () {

  describe("Basic Functionality", async () => {
    it("deployHotswap should not fail", async () => {
      const { factory, tendies, mockNFT } = await loadFixture(classicDeploy);
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
      const { factory, mockFFT, mockNFT, controller, liquidity } = await loadFixture(classicDeploy);
      const [owner] = await ethers.getSigners();

      const liqAddr = await liquidity.getAddress();

      await controller.depositNFT(2);
      await expect(mockNFT.tokenOfOwnerByIndex(liqAddr, 0)).not.be.reverted;
      await expect(mockNFT.tokenOfOwnerByIndex(liqAddr, 1)).not.be.reverted;
    });

    it("should successfully swap FFTs", async () => {
      const [owner] = await ethers.getSigners();
      const { factory, tendies, mockNFT, controller, liquidity } = await loadFixture(classicDeploy);

      const ownerAddr = await owner.getAddress();

      const controllerAddr = controller.getAddress();
      await tendies.increaseAllowance(controllerAddr, BigInt(2000e18));
      await mockNFT.setApprovalForAll(controllerAddr, true);

      await controller.depositNFT(8);
      await controller.depositFFT(BigInt(900e18));

      await controller.updatePrice();

      console.log("Before swap\n------------------");
      console.log(); console.log();
      console.log(await controller.decimals())
      console.log(await tendies.decimals())
      console.log(await controller.queryLiquid(0));
      console.log(await controller.queryLiquid(1));
      console.log(await controller._price());
      console.log("Balances", await mockNFT.balanceOf(ownerAddr), await tendies.balanceOf(ownerAddr));




      // await expect(controller.swapFFT(BigInt(500e18))).to.not.reverted;

      console.log("After swap\n------------------");
      console.log(); console.log();
      const tx = await controller.swapFFT(3);
      const rcpt = await tx.wait();

      for (const log of rcpt?.logs ?? []) {
        if ("fragment" in log) {
          console.log(`${log.fragment.name} => ${log.args}`);
        }
      }

      console.log(await controller.queryLiquid(0));
      console.log(await controller.queryLiquid(1));

      try {
        await controller.withdrawLiquidity(0);
      } catch (err) {
        console.log(err);
      }

      try {
        await controller.withdrawLiquidity(1);
      } catch (err) {
        console.log(err);
      }

      //await expect(controller.withdrawLiquidity(0)).to.not.reverted;
      // console.log(await controller.queryLiquid(0));

      console.log("Balances", await mockNFT.balanceOf(ownerAddr), await tendies.balanceOf(ownerAddr));

      console.log("Withdrawing...");

      // await expect(controller.queryLiquid(1)).to.be.reverted;
      await expect(controller.claimAllFees()).to.not.reverted;
    });

    it("should successfully swap NFTs", async () => {
      const [owner] = await ethers.getSigners();
      const { factory, tendies, mockNFT, controller, liquidity } = await loadFixture(classicDeploy);
      const ownerAddr = await owner.getAddress();

      const controllerAddr = controller.getAddress();
      await tendies.increaseAllowance(controllerAddr, BigInt(1000e18));
      await mockNFT.setApprovalForAll(controllerAddr, true);

      await controller.depositNFT(10);
      await controller.depositFFT(BigInt(300e18));

      await controller.updatePrice();


      console.log("Before swap\n------------------");
      console.log(); console.log();
      console.log(await controller.decimals())
      console.log(await tendies.decimals())
      console.log(await controller.queryLiquid(0));
      console.log(await controller.queryLiquid(1));
      console.log(await controller._price());
      console.log("Balances", await mockNFT.balanceOf(ownerAddr), await tendies.balanceOf(ownerAddr));


      console.log("After swap\n------------------");
      console.log(); console.log();
      const tx = await controller.swapNFT(4);
      const rcpt = await tx.wait();

      for (const log of rcpt?.logs ?? []) {
        if ("fragment" in log) {
          console.log(`${log.fragment.name} => ${log.args}`);
        }
      }




      // await expect().not.reverted;

      console.log(await controller.queryLiquid(0));
      console.log(await controller.queryLiquid(1));
      console.log(await controller._price());
      console.log("Balances", await mockNFT.balanceOf(ownerAddr), await tendies.balanceOf(ownerAddr));
    });

  });
});

