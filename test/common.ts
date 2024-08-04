import { ethers } from "hardhat";
import { ERC721, HotswapController, HotswapLiquidity, MockERC20, MockNonFunLady, ParityPractice, TestnetTendies } from "../typechain-types";
import { AddressLike, ContractTransactionResponse, Signer } from "ethers";
import { HotswapFactory } from "../typechain-types/HotswapFactory_flattened.sol";


export type TokenKind = "tendies" | "pap";
export const DEPLOY_FEE = 1e15;

interface TestContext {
  mockNFT: MockNonFunLady;
  mockFFT: MockERC20;
  tendies: TestnetTendies;
  pap: ParityPractice;
  factory: HotswapFactory;
  controller: HotswapController;
  iquidity: HotswapLiquidity;
}

export function random(min = 1, max = 10000) {
  return Math.random() * (max - min) + min;
}

export function randomBig(min = 1, max = 10000) {
  return BigInt(Math.random() * (max - min) + min);
}

export function randomInt(min = 1, max = 10) {
  return Number((Math.random() * (max - min) + min).toFixed());
}

export function calcLimit(nftAmount: number, price: bigint, slippage: number, isNFT = false) {
  const bnftAmount = BigInt(nftAmount);
  const bfftAmount = bnftAmount * price;

  const delta = (bfftAmount / BigInt(100) * BigInt(slippage));

  if (isNFT) {
    return bfftAmount - delta;
  } else {
    return bfftAmount + delta;
  }
}

export async function simLimit(controller: HotswapController, nftAmount: number, slippage: number): Promise<[price: bigint, amount: bigint]> {
  let price = await controller._price();
  let nliq = await controller.nftLiquidity();
  let fliq = await controller.fftLiquidity();;
  const dec = await controller.decimals();
  const scalar = 10 ** Number(dec);

  const nft = BigInt(nftAmount);
  const fft = BigInt(BigInt(nftAmount) * price);

  nliq += nft;
  fliq -= fft;

  price = fliq / nliq;

  const bnftAmount = BigInt(nftAmount);
  const bfftAmount = bnftAmount * price;

  const delta = (bfftAmount / BigInt(100) * BigInt(slippage));

  return [price, bfftAmount - delta];
}



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

export async function transferNFTs(source: ERC721, amount: number, destAddr: AddressLike) {
  const signer = source.runner as Signer;
  const signerAddr = await signer.getAddress();

  // await source.setApprovalForAll(signerAddr, true);

  for (let i = 0; i < amount; i++) {
    const tokenId = await source.tokenOfOwnerByIndex(signerAddr, 0);
    await source.safeTransferFrom(signerAddr, destAddr, BigInt(tokenId));
  }
}

export async function deploy(kind: TokenKind) {
  const [owner, user] = await ethers.getSigners();
  const HotswapFactory = await ethers.getContractFactory("HotswapFactory");
  const HotswapController = await ethers.getContractFactory("HotswapController");
  const HotswapLiquidity = await ethers.getContractFactory("HotswapLiquidity");

  const factory = await HotswapFactory.deploy();
  let mockNFT: MockNonFunLady = await (await ethers.getContractFactory("MockNonFunLady")).deploy()
  const mockFFT = await (await ethers.getContractFactory("MockERC20")).deploy()
  let tendies: TestnetTendies = await (await ethers.getContractFactory("TestnetTendies")).deploy()
  let pap: ParityPractice = await (await ethers.getContractFactory("ParityPractice")).deploy()

  ethers.provider.send("hardhat_setBalance", [
    await owner.getAddress(),
    "0x10000000000000000000000000000000000000000",
  ]);

  await mockNFT.flipSaleState();

  await mockNFT.mintLady(30, {
    value: 1800000000
  });

  await mockNFT.mintLady(30, {
    value: 1800000000
  });

  await mockNFT.mintLady(30, {
    value: 1800000000
  });

  await mockNFT.mintLady(30, {
    value: 1800000000
  });

  await mockNFT.mintLady(30, {
    value: 1800000000
  });

  await mockNFT.mintLady(30, {
    value: 1800000000
  });

  await mockNFT.mintLady(30, {
    value: 1800000000
  });

  await tendies.set("Testnet Tendies", "TT", BigInt(10000e18));

  for (let i = 0; i < 10; i++) {
    await tendies.mintAdmin();
  }




  const fft = kind == "tendies" ? tendies : pap;

  const nftAddr = await mockNFT.getAddress();
  const fftAddr = await fft.getAddress();

  const tx = await factory.deployHotswap(nftAddr, fftAddr, {
    value: BigInt(DEPLOY_FEE)
  });

  const [controllerAddr, liquidityAddr] = await extractDeployEvent(tx);

  let controller = await HotswapController.attach(controllerAddr) as HotswapController;
  let liquidity = await HotswapLiquidity.attach(liquidityAddr) as HotswapLiquidity;

  console.log(`\n\nController: ${controllerAddr}\nLiquidity: ${liquidityAddr}`);
  console.log(); console.log();

  mockNFT = mockNFT.connect(user);
  tendies = tendies.connect(user);
  pap = pap.connect(user);
  controller = controller.connect(user);
  liquidity = liquidity.connect(user);

  await mockNFT.setApprovalForAll(controllerAddr, true);
  return { mockNFT, mockFFT, tendies, pap, factory, controller, liquidity }
}


export function classicDeploy() { return deploy("tendies"); }

export function papDeploy() { return deploy("pap"); }

export async function outputLogs(act: Promise<ContractTransactionResponse>) {
  const tx = await act;
  const rcpt = await tx.wait()

  for (const log of rcpt?.logs ?? []) {
    if ("fragment" in log) {
      console.log(`${log.fragment.name} => ${log.args}`);
    }
  }
};

export async function readSwap(act: Promise<ContractTransactionResponse>) {
  const tx = await act;
  const rcpt = await tx.wait()

  for (const log of rcpt?.logs ?? []) {
    if ("fragment" in log) {
      if (log.fragment.name == "Swap") {
        let nftAmount = BigInt(log.args[0]);
        let fftAmount = BigInt(log.args[1]);
        let price = BigInt(log.args[3]);

        return {
          nftAmount,
          fftAmount,
          price
        };
      }

      // console.log(`${log.fragment.name} => ${log.args}`);
    }
  }


}
