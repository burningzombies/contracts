import { ethers } from "hardhat";
import Artifact from "../artifacts/contracts/BurningZombiesMarket.sol/BurningZombiesMarket.json";
import { pinJSONToIPFS } from "./utils"; // eslint-disable-line node/no-missing-import

const MASTER_ADDR = "0xa9EDaf66c717808A30dfDEaf2490e3147a145fb5";

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
