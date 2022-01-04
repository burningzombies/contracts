import { ethers } from "hardhat";
import Artifact from "../artifacts/contracts/BurningZombiesERC20.sol/BurningZombiesERC20.json";
import { pinJSONToIPFS } from "./utils"; // eslint-disable-line node/no-missing-import

const main = async () => {
  const tokenFactory = await ethers.getContractFactory("BurningZombiesERC20");
  const token = await tokenFactory.deploy();

  await token.deployed();

  const res = await pinJSONToIPFS(Artifact.abi);

  process.stdout.write(token.address + "\n");
  process.stdout.write(res.data.IpfsHash + "\n");
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
