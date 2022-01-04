import { ethers } from "hardhat";
import Artifact from "../artifacts/contracts/BurningZombiesMarket.sol/BurningZombiesMarket.json";
import { pinJSONToIPFS } from "./utils"; // eslint-disable-line node/no-missing-import

const MASTER_ADDR = "0x4ED4140481cb5C38A4e67A213891D360a5eCEF35";

const main = async () => {
  const marketFactory = await ethers.getContractFactory("BurningZombiesMarket");
  const market = await marketFactory.deploy(MASTER_ADDR, 3, 5, 12);

  await market.deployed();

  const tx = await market.unpause();
  await tx.wait();

  const res = await pinJSONToIPFS(Artifact.abi);

  process.stdout.write(market.address + "\n");
  process.stdout.write(res.data.IpfsHash + "\n");
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
