import { ethers } from "hardhat";
import Artifact from "../artifacts/contracts/BurningZombiesMarket.sol/BurningZombiesMarket.json";
import { pinJSONToIPFS } from "./utils"; // eslint-disable-line node/no-missing-import

const MASTER_ADDR = "0x05F3Fd37b63B4C9B7BB9EFC973280F360F417309";

const main = async () => {
  const [owner] = await ethers.getSigners();

  const marketFactory = await ethers.getContractFactory("BurningZombiesMarket");
  const market = await marketFactory.deploy(
    MASTER_ADDR,
    1,
    3,
    3,
    await owner.getAddress(),
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
