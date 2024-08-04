import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { ethers } from "hardhat";
import { calcLimit, classicDeploy, outputLogs, random, randomBig, randomInt, readSwap, simLimit, transferNFTs } from "./common";
import chai, { expect } from "chai";

const SLIPPAGE = 5;

describe("Classic Hotswap Tests", function () {
  it("Should use the same decimals as it's token", async () => {
    const { tendies, controller, liquidity } = await loadFixture(classicDeploy);
    const [owner, user] = await ethers.getSigners();

    expect(await controller.decimals()).equal(await tendies.decimals());
  });

  it("Should successfully deposit NFT", async () => {
    const { mockNFT, controller, liquidity } = await loadFixture(classicDeploy);
    const [owner, user] = await ethers.getSigners();

    const xmockNFT = mockNFT.connect(owner);


    let total = 0;

    for (let i = 0; i < 10; i++) {
      const amount = randomInt();
      total += amount;

      await transferNFTs(xmockNFT as any, amount, user);
      await controller.depositNFT(amount);
    }

    expect(await mockNFT.balanceOf(liquidity)).equal(BigInt(total), "Inaccurate NFT balance");
    expect(await controller.nftLiquidity()).equal(BigInt(total), "Inaccurate NFT liquidity");
  });

  it("Should successfully deposit FFT", async () => {
    const { tendies, controller, liquidity } = await loadFixture(classicDeploy);
    const [owner, user] = await ethers.getSigners();

    const xtendies = tendies.connect(owner);

    let total = BigInt(0);

    for (let i = 0; i < 10; i++) {
      const amount = randomBig(1e15, 10000e18);
      total += amount;

      await xtendies.transfer(user, amount);
      await tendies.increaseAllowance(controller, amount);
      await controller.depositFFT(amount);
    }

    expect(await tendies.balanceOf(liquidity)).equal(BigInt(total), "Inaccurate FFT balance");
    expect(await controller.fftLiquidity()).equal(BigInt(total), "Inaccurate FFT liquidity");
  });

  it("Should correctly execute swapFFT", async () => {
    const { mockNFT, tendies, controller, liquidity } = await loadFixture(classicDeploy);
    const [owner, user] = await ethers.getSigners();

    const xmockNFT = mockNFT.connect(owner);
    const xtendies = tendies.connect(owner);

    const nftAmount = randomInt(20, 100);
    const fftAmount = randomBig(1e15, 100e18);
    const swapChunk = Number(Math.floor((nftAmount / 10)).toFixed());

    await transferNFTs(xmockNFT as any, nftAmount, user);
    await xtendies.transfer(user, fftAmount);
    await tendies.increaseAllowance(controller, fftAmount);

    await controller.depositNFT(nftAmount);
    await controller.depositFFT(fftAmount);

    for (let i = 0; i < 10; i++) {
      const price = await controller._price();
      const limit = calcLimit(swapChunk, price, SLIPPAGE);

      const nBalBF = await mockNFT.balanceOf(user);
      const fBalBF = await tendies.balanceOf(user);

      await xtendies.transfer(user, limit);
      await tendies.increaseAllowance(controller, limit);

      const swap = await readSwap(controller.swapFFT(swapChunk, limit));
      chai.assert(swap != null, "Hotswap did not return any swap events");

      if (!swap) {
        return;
      }

      const nBalAF = await mockNFT.balanceOf(user);
      const fBalAF = await tendies.balanceOf(user);

      const nDelta = nBalAF - nBalBF;
      const fDelta = fBalAF - fBalBF;

      expect(nDelta).eq(swap.nftAmount, "Hotswap did not report the correct NFT swap amount");
      expect(fDelta).lte(limit, "Hotswap did not uphold swap limit");
      expect(swap.nftAmount).lte(swapChunk, "Hotswap swapped more NFTs than specified");
      expect(swap.fftAmount).lte(limit, "Hotswap did not uphold swap limit");
      expect(price * swap.nftAmount).equal(swap.fftAmount, "Hotswap may have used an incorrect price");
    }
  });

  it("Should correctly execute swapNFT", async () => {
    const { mockNFT, tendies, controller, liquidity } = await loadFixture(classicDeploy);
    const [owner, user] = await ethers.getSigners();

    const xmockNFT = mockNFT.connect(owner);
    const xtendies = tendies.connect(owner);

    const nftAmount = randomInt(20, 100);
    const fftAmount = randomBig(1e15, 100e18);
    const swapChunk = Number(Math.floor((nftAmount / 10)).toFixed());

    await transferNFTs(xmockNFT as any, nftAmount * 2, user);
    await xtendies.transfer(user, fftAmount);
    await tendies.increaseAllowance(controller, fftAmount);

    await controller.depositNFT(nftAmount);
    await controller.depositFFT(fftAmount);


    for (let i = 0; i < 10; i++) {
      const [imPrice, limit] = await simLimit(controller, swapChunk, SLIPPAGE)


      // await transferNFTs(xmockNFT as any, swapChunk, user);

      const nBalBF = await mockNFT.balanceOf(user);
      const fBalBF = await tendies.balanceOf(user);

      const swap = await readSwap(controller.swapNFT(swapChunk, limit));
      chai.assert(swap != null, "Hotswap did not return any swap events");

      if (!swap) {
        return;
      }

      const nBalAF = await mockNFT.balanceOf(user);
      const fBalAF = await tendies.balanceOf(user);

      const nDelta = Number(Math.abs(Number(nBalBF) - Number(nBalAF)));
      const fDelta = fBalAF - fBalBF;



      expect(nDelta).eq(swap.nftAmount, "Hotswap did not report the correct NFT swap amount");
      expect(fDelta).gte(limit, "Hotswap did not uphold swap limit");
      expect(swap.nftAmount).lte(swapChunk, "Hotswap swapped more NFTs than specified");
      expect(swap.fftAmount).gte(limit, "Hotswap did not uphold swap limit");
      expect(imPrice).eq(swap.price, "Hotswap did not propertly calculate impact price");
      expect(imPrice * swap.nftAmount).equal(swap.fftAmount, "Hotswap may have used an incorrect price");
    }
  });
});