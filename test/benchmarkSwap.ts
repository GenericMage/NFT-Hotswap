import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { ContractTransactionResponse } from "ethers";
import { ethers } from "hardhat";
import { HotswapController, HotswapLiquidity } from "../typechain-types";
import { expect } from "chai";
import { classicDeploy } from "./common";
const DEPLOY_FEE = 1e15;

// 370487n


describe("Swap Benchmarks", function () {
  it("Basic SwapNFT benchamrk", async () => {
    const { factory, tendies, mockNFT, controller, liquidity } = await loadFixture(classicDeploy);
    const [owner] = await ethers.getSigners();

    const ownerAddr = await owner.getAddress();

    const controllerAddr = controller.getAddress();
    await tendies.increaseAllowance(controllerAddr, BigInt(2000e18));
    await mockNFT.setApprovalForAll(controllerAddr, true);

    await controller.depositNFT(8);
    await controller.depositFFT(BigInt(900e18));

    const tx = await controller.swapFFT(BigInt(300e18));
    const rcpt = await tx.wait();

    console.log("Gas used for basic swapNFT", rcpt?.gasUsed);
  })
});