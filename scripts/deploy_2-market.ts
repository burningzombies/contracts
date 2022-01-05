import { ethers } from "hardhat";
import Artifact from "../artifacts/contracts/BurningZombiesMarket.sol/BurningZombiesMarket.json";
import { pinJSONToIPFS } from "./utils"; // eslint-disable-line node/no-missing-import

const MASTER_ADDR = "0xFCf61D1B30ccc38a84B8e42BF06DC918e4B7DCA8";

const main = async () => {
  const marketFactory = await ethers.getContractFactory("BurningZombiesMarket");
  const market = await marketFactory.deploy(MASTER_ADDR, 3, 5, 12);

  await market.deployed();

  const res = await pinJSONToIPFS(Artifact.abi);

  process.stdout.write(market.address + "\n");
  process.stdout.write(res.data.IpfsHash + "\n");
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
