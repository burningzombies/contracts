import { ethers } from "hardhat";
import Artifact from "../artifacts/contracts/StakingRewards.sol/StakingRewards.json";
import { pinJSONToIPFS } from "./utils"; // eslint-disable-line node/no-missing-import

const REWARDS_ADDR = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
const STAKING_ADDR = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

const main = async () => {
  const stakeFactory = await ethers.getContractFactory("StakingRewards");
  const stake = await stakeFactory.deploy(REWARDS_ADDR, STAKING_ADDR);

  await stake.deployed();

  const res = await pinJSONToIPFS(Artifact.abi);

  process.stdout.write(stake.address + "\n");
  process.stdout.write(res.data.IpfsHash + "\n");
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
