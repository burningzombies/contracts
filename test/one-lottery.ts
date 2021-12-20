import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber, Contract, Signer } from "ethers";

enum State { // eslint-disable-line
  OPEN = 0, // eslint-disable-line
  CLOSED = 1, // eslint-disable-line
}

describe("OneLottery", () => {
  let lottery: Contract;
  let owner: Signer;
  let fee: BigNumber;
  let signers: Array<Signer>;
  let seed: number;

  beforeEach(async () => {
    [owner, ...signers] = await ethers.getSigners();

    const lotterFactory = await ethers.getContractFactory("OneLottery");
    lottery = await lotterFactory.deploy(ethers.utils.parseUnits("0.05", 18));
    await lottery.deployed();

    fee = await lottery.fee();
    seed = Math.floor(Math.random() * new Date().getTime());
  });

  it("Should see fee", async () => {
    expect(await lottery.connect(owner).fee()).to.be.equal(fee);
  });

  it("Should start lottery", async () => {
    expect(await lottery.lotteryState()).to.be.equal(State.CLOSED);

    await lottery.start({ value: ethers.utils.parseUnits("1", 18) });

    await expect(lottery.start()).to.be.reverted;
    await expect(lottery.start({ value: ethers.utils.parseUnits("1", 18) })).to
      .be.reverted;
    await expect(lottery.connect(signers[0]).start()).to.be.reverted;

    expect(await lottery.lotteryState()).to.be.equal(State.OPEN);
  });

  it("Should draw", async () => {
    // start
    await lottery.start({ value: ethers.utils.parseUnits("1", 18) });

    // join
    for (let i = 0; signers.length > i; i++) {
      await lottery.connect(signers[i]).participate(1, {
        value: fee,
      });
    }

    const lengthOf = await lottery.lengthOf();
    expect(lengthOf.toNumber()).to.be.equal(signers.length);

    for (let i = 0; signers.length > i; i++) {
      expect(await lottery.tickets(await signers[i].getAddress())).to.be.equal(
        BigNumber.from(1)
      );
    }

    const prize = BigNumber.from(signers.length)
      .mul(fee)
      .add(ethers.utils.parseUnits("1", 18));

    expect(await lottery.prize()).to.be.equal(prize);
    expect(await ethers.provider.getBalance(lottery.address)).to.be.equal(
      prize
    );

    const draw = await lottery.finalize(seed);
    const receipt = await draw.wait();
    const winner = receipt.events[0].args.winner;

    expect(draw).to.emit(lottery, "Winner");
    expect(ethers.utils.isAddress(winner)).to.be.equal(true);

    expect(await ethers.provider.getBalance(lottery.address)).to.be.equal(
      BigNumber.from(0)
    );

    await expect(lottery.owner()).to.be.reverted;

    process.stdout.write(`    > Winner: ${winner}\n`);
  });

  it("Should see tickets", async () => {
    // start
    await lottery.start({ value: ethers.utils.parseUnits("1", 18) });

    await expect(lottery.participate(31, { value: fee.mul(31) })).to.be
      .reverted;

    await lottery.connect(signers[0]).participate(24, {
      value: fee.mul(BigNumber.from(24)),
    });

    await lottery.connect(signers[1]).participate(10, {
      value: fee.mul(BigNumber.from(10)),
    });

    await lottery.connect(signers[2]).participate(3, {
      value: fee.mul(BigNumber.from(3)),
    });

    expect(await lottery.lengthOf()).to.be.equal(BigNumber.from(37));

    expect(await lottery.tickets(await signers[0].getAddress())).to.be.equal(
      BigNumber.from(24)
    );
    expect(await lottery.tickets(await signers[1].getAddress())).to.be.equal(
      BigNumber.from(10)
    );
    expect(await lottery.tickets(await signers[2].getAddress())).to.be.equal(
      BigNumber.from(3)
    );
  });
});
