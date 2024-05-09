import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { ethers } from "hardhat";

describe("HotswapFactory", function() {
  async function deploy() {
    const DexhunePriceDaoFactory = await ethers.getContractFactory("HotswapFactory");
    

    const factory = await DexhunePriceDaoFactory.deploy();
    const mockNFT = await (await ethers.getContractFactory("MockNFT")).deploy()
    const mockFFT = await (await ethers.getContractFactory("MockERC20")).deploy()

    return { mockNFT, mockFFT, factory }
  }

  describe("Basic Functionality", async () => {
    it ("deployHotswap should not fail", async () => {
      const { factory, mockFFT, mockNFT } = await loadFixture(deploy);
      const [owner] = await ethers.getSigners();
      const DEPLOY_FEE = 1e15;

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
  });
});

