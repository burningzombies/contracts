import { subtask, task } from "hardhat/config"; // eslint-disable-line

task("lottery", "Print help")
  .addPositionalParam("command")
  .addOptionalParam("fee")
  .addOptionalParam("contract")
  .addFlag("start")
  .addOptionalParam("prize")
  .setAction(async (args: any, hre) => {
    switch (args.command) {
      case "new": {
        await hre.run("new-lottery", {
          fee: args.fee,
          start: args.start,
          prize: args.prize,
        });
        process.exit(0); // eslint-disable-line no-process-exit
      }
      case "start": {
        await hre.run("start-lottery", {
          contract: args.contract,
          prize: args.prize,
        });
        process.exit(0); // eslint-disable-line no-process-exit
      }
      case "finalize": {
        await hre.run("end-lottery", { contract: args.contract });
        process.exit(0); // eslint-disable-line no-process-exit
      }
      default: {
        throw new Error("Not valid command.");
      }
    }
  });

subtask("new-lottery", "Deploy lottery")
  .addParam("fee")
  .addFlag("start")
  .addOptionalParam("prize")
  .setAction(async (args: any, hre) => {
    const lotteryFactory = await hre.ethers.getContractFactory("OneLottery");
    const lottery = await lotteryFactory.deploy(
      hre.ethers.utils.parseUnits(args.fee, 18)
    );
    await lottery.deployed();

    if (args.start)
      await hre.run("start-lottery", {
        prize: args.prize,
        contract: lottery.address,
      });

    process.stdout.write(`${lottery.address}\n`);
  });

subtask("start-lottery", "Start Lottery")
  .addParam("contract")
  .addParam("prize")
  .setAction(async (args: any, hre) => {
    const lottery = await hre.ethers.getContractAt("OneLottery", args.contract);

    const tx = await lottery.start({
      value: hre.ethers.utils.parseUnits(args.prize, 18),
    });
    await tx.wait();
  });

subtask("end-lottery", "Start Lottery")
  .addParam("contract")
  .setAction(async (args: any, hre) => {
    const lottery = await hre.ethers.getContractAt("OneLottery", args.contract);

    const tx = await lottery.finalize(
      Math.floor(Math.random() * new Date().getTime())
    );
    await tx.wait();
  });

task(
  "accounts",
  "Prints the list of accounts",
  async (taskArgs: any, hre: any) => {
    if (taskArgs.new) {
      hre.run("new-accounts", { count: taskArgs.count });
      process.exit(0);
    }
    const accounts = await hre.ethers.getSigners();

    for (const account of accounts) {
      console.log(
        account.address +
          " " +
          parseInt(
            hre.ethers.utils.formatUnits(
              await hre.ethers.provider.getBalance(await account.getAddress()),
              18
            )
          ).toFixed(2)
      );
    }
  }
)
  .addFlag("new")
  .addOptionalParam("count");

subtask(
  "new-accounts",
  "Generate new accounts",
  async (taskArgs: any, hre: any) => {
    const count = taskArgs.count ? taskArgs.count : 1;

    for (let i = 0; count > i; i++) {
      process.stdout.write(
        hre.ethers.Wallet.createRandom().privateKey.split("0x").join("") + "\n"
      );
    }
  }
).addOptionalParam("count");
