import { ethers } from "hardhat";
import Artifact from "../artifacts/contracts/StakingRewards.sol/StakingRewards.json";
import { pinJSONToIPFS } from "./utils"; // eslint-disable-line node/no-missing-import

const REWARDS_ADDR = "0x9c4f88408f9f003Fb10f106E7A69989bB4f3452f";
const STAKING_ADDR = "0x1b72CFde16E5a33a36eAAFbf2eb9CDEd02B09577";

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
