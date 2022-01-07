import { ethers } from "hardhat";
import Artifact from "../artifacts/contracts/StakingRewards.sol/StakingRewards.json";
import { pinJSONToIPFS } from "./utils"; // eslint-disable-line node/no-missing-import

const REWARDS_ADDR = "0x2017E625a7661F65Dd5Ee0a61C1B84d601212131";
const STAKING_ADDR = "0x15Ee4A7a3f9DCe5ABc2Ca40B37729B5d872e90Ef";

const main = async () => {
  const stakeFactory = await ethers.getContractFactory("StakingRewards");
  const stake = await stakeFactory.deploy(REWARDS_ADDR, STAKING_ADDR);

  await stake.deployed();

  const duration = await stake.setRewardsDuration(31556926);
  await duration.wait();

  const token = await ethers.getContractAt("BurningZombiesERC20", REWARDS_ADDR);
  const transfer = await token.transfer(
    stake.address,
    ethers.utils.parseUnits("3000000", 18)
  );
  await transfer.wait();

  const update = await stake.notifyRewardAmount(
    ethers.utils.parseUnits("3000000", 18),
    { gasLimit: 6000000 }
  );
  await update.wait();

  const res = await pinJSONToIPFS(Artifact.abi);

  process.stdout.write(stake.address + "\n");
  process.stdout.write(res.data.IpfsHash + "\n");
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
