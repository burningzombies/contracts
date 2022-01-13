import { ethers } from "hardhat";
import Artifact from "../artifacts/contracts/BurningZombiesMarket.sol/BurningZombiesMarket.json";
import { pinJSONToIPFS } from "./utils"; // eslint-disable-line node/no-missing-import

const MASTER_ADDR = "0x8B301E92Ed8565786F467c9D4655C8711c26AAfa";

const main = async () => {
  const marketFactory = await ethers.getContractFactory("BurningZombiesMarket");
  const market = await marketFactory.deploy(
    MASTER_ADDR,
    1,
    2,
    3,
    "0xaBE94c96fd7C01Acaa312aeDC10e86828C65eC48",
    9
  );

  await market.deployed();

  const res = await pinJSONToIPFS(Artifact.abi);

  process.stdout.write(market.address + "\n");
  process.stdout.write(res.data.IpfsHash + "\n");
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
