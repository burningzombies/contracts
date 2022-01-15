import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber, Contract, Signer } from "ethers";

enum State { // eslint-disable-line
  OPEN = 0, // eslint-disable-line
  CLOSED = 1, // eslint-disable-line
}

describe("OneLottery", () => {
  let lottery: Contract;
  let token: Contract;
  let owner: Signer;
  let fee: BigNumber;
  let signers: Array<Signer>;
  let seed: number;

  beforeEach(async () => {
    [owner, ...signers] = await ethers.getSigners();

    const tokenFactory = await ethers.getContractFactory("ERC721Mock");
    token = await tokenFactory.deploy(1);
    await token.deployed();

    const lotteryFactory = await ethers.getContractFactory("NFTLottery");
    lottery = await lotteryFactory.deploy(ethers.utils.parseUnits("0.1", 18));
    await lottery.deployed();

    fee = await lottery.fee();
    seed = Math.floor(Math.random() * new Date().getTime());
  });

  it("Should see fee", async () => {
    expect(await lottery.connect(owner).fee()).to.be.equal(fee);
  });

  it("Should start lottery", async () => {
    expect(await lottery.lotteryState()).to.be.equal(State.CLOSED);

    await (await token.approve(lottery.address, 0)).wait();
    await lottery.start(token.address, 0);

    expect(await token.ownerOf(0)).to.be.equal(lottery.address);

    await expect(lottery.connect(signers[0]).start(token.address, 0)).to.be
      .reverted;

    expect(await lottery.lotteryState()).to.be.equal(State.OPEN);
  });

  it("Should draw", async () => {
    // start
    await (await token.approve(lottery.address, 0)).wait();
    await lottery.start(token.address, 0);

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

    const fees = BigNumber.from(signers.length).mul(fee);

    expect(await lottery.prizeTokenId()).to.be.equal(0);
    expect(await lottery.tokenAddress()).to.be.equal(token.address);
    expect(
      await ethers.provider.getBalance(
        "0xaBE94c96fd7C01Acaa312aeDC10e86828C65eC48"
      )
    ).to.be.equal(fees);

    const draw = await lottery.finalize(seed);
    const receipt = await draw.wait();
    const winner = receipt.events[2].args.winner;

    expect(draw).to.emit(lottery, "Winner");
    expect(ethers.utils.isAddress(winner)).to.be.equal(true);

    expect(await token.ownerOf(0)).to.be.equal(winner);

    process.stdout.write(`    > Winner: ${winner}\n`);
  });

  it("Should see tickets", async () => {
    // start
    await (await token.approve(lottery.address, 0)).wait();
    await lottery.start(token.address, 0);

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
