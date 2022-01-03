import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract, Signer } from "ethers";

describe("StakingRewards", () => {
  let rewardsToken: Contract;
  let stakingToken: Contract;
  let stakingRewards: Contract;
  let owner: Signer;

  const totalERC20 = ethers.utils.parseUnits("24000000", 18);
  const reward = totalERC20.div(100).mul(50);

  beforeEach(async () => {
    [owner] = await ethers.getSigners();

    const rewardsTokenFactory = await ethers.getContractFactory("ERC20Mock");
    rewardsToken = await rewardsTokenFactory.deploy(totalERC20);
    await rewardsToken.deployed();

    const stakingTokenFactory = await ethers.getContractFactory("ERC721Mock");
    stakingToken = await stakingTokenFactory.deploy(30);
    await stakingToken.deployed();

    const stakingRewardsFactory = await ethers.getContractFactory(
      "StakingRewards"
    );
    stakingRewards = await stakingRewardsFactory.deploy(
      rewardsToken.address,
      stakingToken.address
    );
    await stakingRewards.deployed();

    await stakingRewards.setRewardsDuration(604800);
    await stakingRewards.setPeriodFinish(1654266160);
    await rewardsToken.transfer(stakingRewards.address, reward);
    await stakingRewards.notifyRewardAmount(reward);

    await stakingToken.setApprovalForAll(stakingRewards.address, true);
  });

  it("Should be deployed", async () => {
    const reward = await stakingRewards.rewardsToken();
    const stake = await stakingRewards.stakingToken();

    expect(reward).to.be.equal(rewardsToken.address);
    expect(stake).to.be.equal(stakingToken.address);
  });

  it("Should stake", async () => {
    await expect(stakingRewards.stake([0, 1, 2, 3, 4, 5]))
      .to.emit(stakingRewards, "Staked")
      .withArgs(await owner.getAddress(), [0, 1, 2, 3, 4, 5]);
  });

  it("Should withdraw", async () => {
    await expect(stakingRewards.stake([0, 1, 2, 3, 4, 5]))
      .to.emit(stakingRewards, "Staked")
      .withArgs(await owner.getAddress(), [0, 1, 2, 3, 4, 5]);

    await expect(stakingRewards.withdraw([0, 1, 2, 3, 4, 5]))
      .to.emit(stakingRewards, "Withdrawn")
      .withArgs(await owner.getAddress(), [0, 1, 2, 3, 4, 5]);
  });

  it("Should get rewards", async () => {
    await expect(stakingRewards.stake([0, 1, 2, 3, 4, 5]))
      .to.emit(stakingRewards, "Staked")
      .withArgs(await owner.getAddress(), [0, 1, 2, 3, 4, 5]);

    await expect(stakingRewards.getReward()).to.emit(
      stakingRewards,
      "RewardPaid"
    );
  });
});
