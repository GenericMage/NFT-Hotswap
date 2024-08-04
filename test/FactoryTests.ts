import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { ethers } from "hardhat";
import { calcLimit, classicDeploy, outputLogs, random, randomBig, randomInt, readSwap, simLimit, transferNFTs } from "./common";
import chai, { expect } from "chai";
import { ZeroAddress } from "ethers";

describe("Factory Tests", function () {
  it("Should successfully swap controllers", async () => {
    const HotswapFactory = await ethers.getContractFactory("HotswapFactory");

    const { controller, liquidity, factory } = await loadFixture(classicDeploy);

    const nFactory = await HotswapFactory.deploy();

    await factory.setFactory(controller, nFactory);
    await nFactory.setLiquidity(controller, liquidity);

    const xpair = await factory.pairs(0);

    await expect(xpair.controller).to.equal(ZeroAddress);
    await expect(xpair.liquidity).to.equal(ZeroAddress);

    const pair = await nFactory.pairs(0);

    expect(pair.controller).equal(await controller.getAddress());
    expect(pair.liquidity).equal(await liquidity.getAddress());
    expect(await controller.owner()).equal(await nFactory.getAddress(), "Factory did not transfer ownership properly");
  });

  it("Should correctly set liquidity", async () => {
    const HotswapLiquidity = await ethers.getContractFactory("HotswapLiquidity");
    const { controller, liquidity, factory } = await loadFixture(classicDeploy);

    const nft = await controller.NFT();
    const fft = await controller.FFT();

    const nliq = await HotswapLiquidity.deploy(nft, fft);
    await factory.setLiquidity(await controller.getAddress(), nliq);

    expect(await controller._liquidity()).equal(await nliq.getAddress(), "Hotswap did not correctly set liquidity");
    expect(await nliq.controller()).equal(await controller.getAddress(), "Hotswap did not correctly set controller");
  });

  it("Should correctly set controller", async () => {
    const HotswapController = await ethers.getContractFactory("HotswapController");
    const { controller, liquidity, factory } = await loadFixture(classicDeploy);

    const nft = await liquidity.NFT();
    const fft = await liquidity.FFT();

    const ncontroller = await HotswapController.deploy(nft, fft);
    await factory.setController(liquidity, ncontroller);

    expect(await liquidity.controller()).equal(await ncontroller.getAddress(), "Hotswap did not correctly set controller");
    expect(await ncontroller._liquidity()).equal(await liquidity.getAddress(), "Hotswap did not correctly set liquidity");
  });


});