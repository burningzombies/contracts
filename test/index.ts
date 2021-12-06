import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber, Contract, Signer } from "ethers";

describe("Burning Zombies", function () {
  let start: number;
  let duration: number;

  let owner: Signer;
  let addrs: Array<Signer>;

  let contract: Contract;
  let nemo: Contract;
  let nemoMinters: Contract;
  let splitter: Contract;
  let market: Contract;

  beforeEach(async () => {
    start = Math.floor(new Date().getTime() / 1000);
    duration = 60 * 60 * 7;
    [owner, ...addrs] = await ethers.getSigners();

    // deploy payment splitter
    const payees = [
      await addrs[0].getAddress(),
      await addrs[1].getAddress(),
      await addrs[2].getAddress(),
      await addrs[3].getAddress(),
    ];
    const shares = [45, 20, 15, 20];

    const splitter_ = await ethers.getContractFactory("PaymentSplitter");
    splitter = await splitter_.deploy(payees, shares);
    await splitter.deployed();

    // deploy nemo mock
    const nemo_ = await ethers.getContractFactory("NeonMonsters");
    nemo = await nemo_.deploy();
    await nemo.deployed();

    // deploy nemo minters
    const nemoMinters_ = await ethers.getContractFactory("NeonMonstersMinters");
    nemoMinters = await nemoMinters_.deploy();
    await nemoMinters.deployed();

    const factory = await ethers.getContractFactory("BurningZombiesERC721");
    contract = await factory.deploy(
      splitter.address,
      "ipfs://uri/",
      start,
      duration
    );
    await contract.deployed();

    await contract.setNeonMonstersContract(nemo.address);
    await contract.setNeonMonstersMintersContract(nemoMinters.address);

    // deploy market
    const market_ = await ethers.getContractFactory("BurningZombiesMarket");
    market = await market_.deploy(contract.address, 3, 5, 12);
    await market.deployed();

    await contract.setReflectionDynamics(336, 30, 0, "1500000000000000000", 0);
  });

  it("Should update reflection dynamics", async () => {
    await contract.setReflectionDynamics(756, 20, 0, "2000000000000000000", 0);

    await contract
      .connect(addrs[0])
      .mintTokens(1, { value: "2000000000000000000" });

    expect(
      (await contract.connect(addrs[0]).currentTokenPrice()).toString()
    ).to.be.equal("2000000000000000000");
  });

  it("Should discount for nemo minters", async () => {
    await nemoMinters.setMinter(await owner.getAddress());
    await contract.mintTokens(1, { value: "150000000000000000" });

    const balance = await contract.balanceOf(await owner.getAddress());
    expect(balance.toNumber()).to.be.equal(1);

    const reflectionBalance = await contract.reflectionBalance();
    expect(reflectionBalance.toString()).to.be.equal("45000000000000000");

    const totalDividend = await contract.totalDividend();
    expect(totalDividend.toString()).to.be.equal("14880952380952");

    const splitterBalance = await ethers.provider.getBalance(splitter.address);
    expect(splitterBalance.toString()).to.be.equal("105000000000000000");
    await expect(contract.mintTokens(1, { value: "150000000000000000" })).to.be
      .reverted;
  });

  it("Should discount for nemo holders", async () => {
    for (let i = 0; i < 250; i++) {
      await contract
        .connect(addrs[1])
        .mintTokens(1, { value: "1500000000000000000" });
      process.stdout.write(`\r    > Mint index: ${i}`);
    }
    console.log("");

    for (let i = 0; i < 86; i++) {
      await contract
        .connect(addrs[2])
        .mintTokens(1, { value: "1500000000000000000" });
      process.stdout.write(`\r    > Mint index/2: ${i}`);
    }
    console.log("");
    await contract.mintTokens(1, { value: "750000000000000000" });
    await expect(contract.mintTokens(1, { value: "750000000000000000" })).to.be
      .reverted;

    const balance = await contract.balanceOf(await owner.getAddress());
    expect(balance.toNumber()).to.be.equal(1);
  });

  it("Should claim rewards", async () => {
    const start = Math.floor(new Date().getTime() / 1000);
    const duration = 1600;

    await contract.setSaleStart(start);
    await contract.setSaleDuration(duration);

    expect((await contract.saleStartsAt()).toNumber()).to.be.equal(start);
    expect((await contract.saleDuration()).toNumber()).to.be.equal(duration);

    let i = 0;
    while (true) {
      const addrsIndex: number = parseInt((i / 250).toString());

      try {
        await contract.connect(addrs[addrsIndex]).mintTokens(1, {
          value: await contract.connect(addrs[addrsIndex]).currentTokenPrice(),
        });

        if (i === 1)
          await expect(
            contract
              .connect(addrs[addrsIndex])
              .transferFrom(
                await addrs[addrsIndex].getAddress(),
                await owner.getAddress(),
                0
              )
          ).to.be.reverted;

        process.stdout.write(`\r    > Mint index: ${i}`);
      } catch (err: any) {
        break;
      }
      i++;
    }
    console.log("");

    i = 0;
    while (true) {
      const addrsIndex: number = parseInt((i / 250).toString());

      if (i === 1)
        await expect(
          contract
            .connect(addrs[addrsIndex])
            .transferFrom(
              await addrs[addrsIndex].getAddress(),
              await owner.getAddress(),
              0
            )
        ).to.be.reverted;
      try {
        await contract
          .connect(addrs[addrsIndex])
          .divideUnclaimedTokenReflection(1);
        process.stdout.write(`\r    > Burn index: ${i}`);
      } catch (err: any) {
        break;
      }
      i++;
    }
    console.log("");

    await contract
      .connect(addrs[0])
      .transferFrom(
        await addrs[0].getAddress(),
        await addrs[9].getAddress(),
        1
      );

    expect(await contract.getReflectionBalance(1)).to.be.equal(
      BigNumber.from("0")
    );

    const initialBalance = await ethers.provider.getBalance(
      await addrs[0].getAddress()
    );
    const reflectionBalance = await contract
      .connect(addrs[0])
      .getReflectionBalances();

    const totalReflectionBalance = await contract.reflectionBalance();

    expect(totalReflectionBalance).to.be.closeTo(
      (await contract.totalDividend()).mul(await contract.totalSupply()),
      1000000000000000
    );

    await contract.connect(addrs[0]).claimRewards();
    const lastBalance = await ethers.provider.getBalance(
      await addrs[0].getAddress()
    );

    const diff = lastBalance
      .add(BigNumber.from("1000000000000000"))
      .sub(initialBalance);
    expect(diff).to.be.most(reflectionBalance);

    expect(await contract.totalDividend()).to.be.gt(BigNumber.from(0));

    const gross = (await contract.totalSupply()).mul(
      BigNumber.from("1500000000000000000")
    );

    const estBalance = gross.sub(await contract.reflectionBalance());
    const splitterBalance = await ethers.provider.getBalance(splitter.address);

    expect(splitterBalance).to.be.equal(estBalance);

    await splitter.pause();
    await expect(splitter.release(await addrs[0].getAddress())).to.be.reverted;

    await splitter.unpause();
    await splitter.release(await addrs[0].getAddress());
    await splitter.release(await addrs[1].getAddress());
    await splitter.release(await addrs[2].getAddress());
    await splitter.release(await addrs[3].getAddress());

    const payee1Balance = await splitter.released(await addrs[0].getAddress());
    const payee2Balance = await splitter.released(await addrs[1].getAddress());
    const payee3Balance = await splitter.released(await addrs[2].getAddress());
    const payee4Balance = await splitter.released(await addrs[3].getAddress());

    expect(payee1Balance).to.be.most(splitterBalance.div(100).mul(45));
    expect(payee2Balance).to.be.most(splitterBalance.div(100).mul(20));
    expect(payee3Balance).to.be.most(splitterBalance.div(100).mul(15));
    expect(payee4Balance).to.be.most(splitterBalance.div(100).mul(20));

    await market.unpause();
    await contract.connect(addrs[0]).approve(market.address, 0);
    await market.connect(addrs[0]).createListing(0, 100);

    await expect(market.buy(0, { value: 100 }))
      .to.emit(market, "Sale")
      .withArgs(await addrs[0].getAddress(), await owner.getAddress(), 0, 100);

    expect((await market.reflectionBalance()).toNumber()).to.be.equal(12);

    await market.claimRewards();
    await contract.connect(addrs[0]).burn(5);
    expect(await contract.getReflectionBalance(5)).to.be.equal(
      BigNumber.from("0")
    );
    await expect(contract.tokenURI(5)).to.be.reverted;
  });

  it("Should return reflection share", async () => {
    const initial = await contract.calculateReflectionShare();

    expect(initial.toNumber()).to.be.equal(30);

    await contract.mintTokens(1, { value: "1500000000000000000" });

    expect((await contract.calculateReflectionShare()).toNumber()).to.be.equal(
      30
    );
  });

  it("Should verify the prices", async () => {
    const price = await contract.connect(addrs[0]).currentTokenPrice();
    expect(price).to.be.equal(BigNumber.from("1500000000000000000"));
  });

  it("Shoul not sell if paused", async () => {
    await contract.mintTokens(1, { value: "1500000000000000000" });
    await contract.approve(market.address, 0);

    await expect(market.createListing(0, 500)).to.be.reverted;
  });

  it("Should send if from owner", async () => {
    await contract.mintTokens(1, { value: "1500000000000000000" });
    await contract.transferFrom(
      await owner.getAddress(),
      await addrs[0].getAddress(),
      0
    );

    expect(await contract.balanceOf(await addrs[0].getAddress())).to.be.equal(
      BigNumber.from("1")
    );

    await expect(
      contract
        .connect(addrs[0])
        .transferFrom(await addrs[0].getAddress(), await owner.getAddress(), 0)
    ).to.be.reverted;
  });

  it("Should not burn if it's active", async () => {
    await contract.mintTokens(1, { value: "1500000000000000000" });
    await expect(contract.burn(0)).be.reverted;
  });
});