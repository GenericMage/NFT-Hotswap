import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { ContractTransactionResponse } from "ethers";
import { ethers } from "hardhat";
import { HotswapController, HotswapLiquidity } from "../typechain-types";
import { expect } from "chai";
import { classicDeploy, outputLogs, papDeploy } from "./common";

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

    it("Should successfully constrain swapFFT", async () => {
      const { factory, tendies, mockNFT, controller, liquidity } = await loadFixture(classicDeploy);
      const [owner] = await ethers.getSigners();
      const liqAddr = await liquidity.getAddress();
      const ownerAddr = await owner.getAddress();

      const controllerAddr = controller.getAddress();
      await tendies.increaseAllowance(controllerAddr, BigInt(1100e18));
      await mockNFT.setApprovalForAll(controllerAddr, true);

      await controller.depositNFT(8);
      await controller.depositFFT(BigInt(900e18));

      const tx = await controller.swapFFT(3, BigInt(200e18));
      const rcpt = await tx.wait();

      for (const log of rcpt?.logs ?? []) {
        if ("fragment" in log) {
          console.log(`${log.fragment.name} => ${log.args}`);
        }
      }
    });

    it("should successfully swap FFTs", async () => {
      const [owner] = await ethers.getSigners();
      const { factory, pap, mockNFT, mockFFT, controller, liquidity } = await loadFixture(papDeploy);

      const ownerAddr = await owner.getAddress();

      const controllerAddr = controller.getAddress();
      await pap.increaseAllowance(controllerAddr, BigInt(2000e18));
      await mockNFT.setApprovalForAll(controllerAddr, true);

      await controller.depositNFT(8);
      await controller.depositNFT(3);
      await controller.depositNFT(10);
      await controller.depositFFT(BigInt(900e18));

      console.log("Before swap\n------------------");
      console.log(); console.log();
      console.log(await controller.decimals())
      console.log(await pap.decimals())
      console.log(await controller.queryLiquid(0, true));
      console.log(await controller.queryLiquid(0, false));
      console.log(await controller._price());
      console.log("Balances", await mockNFT.balanceOf(ownerAddr), await pap.balanceOf(ownerAddr));

      console.log("NFT Liquidity", await mockNFT.balanceOf(liquidity));



      // await expect(controller.swapFFT(BigInt(500e18))).to.not.reverted;

      console.log("After swap\n------------------");
      console.log(); console.log();
      const tx = await controller.swapFFT(3, BigInt(400e18));
      const rcpt = await tx.wait();

      for (const log of rcpt?.logs ?? []) {
        if ("fragment" in log) {
          console.log(`${log.fragment.name} => ${log.args}`);
        }
      }

      // console.log(await controller.queryLiquid(0, true));
      // console.log(await controller.queryLiquid(0, false));

      const bbal = await mockNFT.balanceOf(ownerAddr);

      try {
        await controller.withdrawLiquidity(0, true);
      } catch (err) {
        console.log(err);
      }

      const abal = await mockNFT.balanceOf(ownerAddr);

      expect(bbal).not.eq(abal, "NFT withdrawal failed");
      console.log("WWWW", bbal, abal)

      // try {
      //   await controller.withdrawLiquidity(0, false);
      // } catch (err) {
      //   console.log(err);
      // }

      console.log("BControllerBalance", await pap.balanceOf(await controller.getAddress()));

      // await outputLogs(controller.claimFee(0, false));
      // await outputLogs(controller.claimFee(0, true));
      // await outputLogs(controller.claimFee(1, true));
      // await outputLogs(controller.claimFee(2, true));

      console.log("ControllerBalance", await pap.balanceOf(await controller.getAddress()));

      //await expect(controller.withdrawLiquidity(0)).to.not.reverted;
      // console.log(await controller.queryLiquid(0));

      console.log("Balances", await mockNFT.balanceOf(ownerAddr), await pap.balanceOf(ownerAddr));

      console.log("Withdrawing...");

      // await expect(controller.queryLiquid(1)).to.be.reverted;
      //await expect(controller.claimFee(0, true)).to.not.reverted;
    });

    it("should successfully swap NFTs", async () => {
      const [owner] = await ethers.getSigners();
      const { factory, pap, mockNFT, controller, liquidity } = await loadFixture(papDeploy);
      const ownerAddr = await owner.getAddress();

      const controllerAddr = controller.getAddress();
      await pap.increaseAllowance(controllerAddr, BigInt(1000e6));
      await mockNFT.setApprovalForAll(controllerAddr, true);

      await controller.depositNFT(10);
      await controller.depositFFT(BigInt(300e6));

      //await controller.updatePrice();


      console.log("Before swap\n------------------");
      console.log(); console.log();
      console.log(await controller.decimals())
      console.log(await pap.decimals())
      console.log(await controller.queryLiquid(0, true));
      console.log(await controller.queryLiquid(0, false));
      console.log(await controller._price());
      console.log("Balances", await mockNFT.balanceOf(ownerAddr), await pap.balanceOf(ownerAddr));


      console.log("After swap\n------------------");
      console.log(); console.log();
      const tx = await controller.swapNFT(4, BigInt(30e6));
      const rcpt = await tx.wait();

      for (const log of rcpt?.logs ?? []) {
        if ("fragment" in log) {
          console.log(`${log.fragment.name} => ${log.args}`);
        }
      }




      // await expect().not.reverted;

      console.log(await controller.queryLiquid(0, true));
      console.log(await controller.queryLiquid(0, false));
      console.log(await controller._price());
      console.log("Balances", await mockNFT.balanceOf(ownerAddr), await pap.balanceOf(ownerAddr));
    });


    it("should correctly calculate normalized price", async () => {
      const { factory, pap, mockNFT, controller, liquidity } = await loadFixture(papDeploy);
      const [owner] = await ethers.getSigners();
      const ownerAddr = await owner.getAddress();
      const controllerAddr = await controller.getAddress();


      await pap.increaseAllowance(controllerAddr, BigInt(2000e6));
      await mockNFT.setApprovalForAll(controllerAddr, true);

      await controller.depositNFT(7);
      await controller.depositFFT(BigInt(1002e6));

      console.log(await controller.nftLiquidity());
      console.log(await controller.fftLiquidity());

      const dec = Number(await pap.decimals());
      const enft = Number(await controller.nftLiquidity()) * 10 ** dec;
      const efft = Number(await controller.fftLiquidity());

      const eprice = efft / enft;

      const price = Number(await controller._price()) / 10 ** dec;

      console.log("nft", enft, "fft", efft);
      console.log("Price is", price, eprice);
      console.log("Fees", await controller._fees());

      expect(price.toFixed(4)).equal(eprice.toFixed(4));
    }),

      it("should correctly calculate normalized price", async () => {
        const { factory, pap, mockNFT, controller, liquidity } = await loadFixture(papDeploy);
        const [owner] = await ethers.getSigners();
        const ownerAddr = await owner.getAddress();
        const controllerAddr = await controller.getAddress();


        await pap.increaseAllowance(controllerAddr, BigInt(10000e6));
        await mockNFT.setApprovalForAll(controllerAddr, true);

        await controller.depositNFT(7);
        await controller.depositFFT(BigInt(1002e6));

        console.log(await controller.nftLiquidity());
        console.log(await controller.fftLiquidity());

        const dec = Number(await pap.decimals());
        const enft = Number(await controller.nftLiquidity()) * 10 ** dec;
        const efft = Number(await controller.fftLiquidity());

        const eprice = efft / enft;

        const price = Number(await controller._price()) / 10 ** dec;

        console.log("nft", enft, "fft", efft);
        console.log("Price is", price, eprice);
        console.log("Fees", await controller._fees());

        expect(price.toFixed(4)).equal(eprice.toFixed(4));
      })
  });
});

