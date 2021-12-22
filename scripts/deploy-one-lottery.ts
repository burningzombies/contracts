import { ethers } from "hardhat";
import OneLottery from "../artifacts/contracts/lottery/OneLottery.sol/OneLottery.json";
import { pinJSONToIPFS } from "./utils"; // eslint-disable-line node/no-missing-import

const ARGV = process.argv.slice(2);

async function deploy() {
  if (typeof ARGV[0] === "undefined") throw new Error("Fee is required.");

  const lotteryFactory = await ethers.getContractFactory("OneLottery");
  const lottery = await lotteryFactory.deploy(
    ethers.utils.parseUnits(ARGV[0], 18)
  );
  await lottery.deployed();

  const lotteryABIResponse = await pinJSONToIPFS(
    process.env.PINATA_API_KEY as string,
    process.env.PINATA_API_SECRET as string,
    OneLottery.abi
  );

  return {
    contract: lottery,
    address: lottery.address,
    cid: lotteryABIResponse.data.IpfsHash,
  };
}

async function main() {
  const lottery = await deploy();

  // prettier-ignore
  process.stdout.write(`
  > OneLottery
    - Address: ${lottery.address}
    - Abi:     ${lottery.cid}\n`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});