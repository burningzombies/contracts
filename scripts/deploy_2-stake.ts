import { ethers } from "hardhat";
import Artifact from "../artifacts/contracts/StakingRewards.sol/StakingRewards.json";
import { pinJSONToIPFS } from "./utils"; // eslint-disable-line node/no-missing-import

const REWARDS_ADDR = "0x6F669ddB644964eEB4d6437842800A41e215AE8C";
const STAKING_ADDR = "0xFCf61D1B30ccc38a84B8e42BF06DC918e4B7DCA8";

const main = async () => {
  const stakeFactory = await ethers.getContractFactory("StakingRewards");
  const stake = await stakeFactory.deploy(REWARDS_ADDR, STAKING_ADDR);

  await stake.deployed();

  const duration = await stake.setRewardsDuration(31556926);
  await duration.wait();

  const token = await ethers.getContractAt("BurningZombiesERC20", REWARDS_ADDR);
  const transfer = await token.transfer(
    stake.address,
    ethers.utils.parseUnits("12000000", 18)
  );
  await transfer.wait();

  const update = await stake.notifyRewardAmount(
    ethers.utils.parseUnits("12000000", 18),
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