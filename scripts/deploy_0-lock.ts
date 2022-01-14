import { ethers } from "hardhat";
import BURNLock from "../artifacts/contracts/BURNLock.sol/BURNLock.json";
import { pinJSONToIPFS } from "./utils"; // eslint-disable-line node/no-missing-import

async function main() {
  const start = 1672578061;
  const cliff = 1672664461;
  const end = 1680440461;

  const _ = await ethers.getContractFactory("BURNLock");
  const lock = await _.deploy(
    "0x9c4f88408f9f003Fb10f106E7A69989bB4f3452f",
    start,
    cliff,
    end
  );
  await lock.deployed();
  console.log(lock.address);

  const token = await ethers.getContractAt(
    "BurningZombiesERC20",
    "0x9c4f88408f9f003Fb10f106E7A69989bB4f3452f"
  );

  await (await token.approve(lock.address, "1196723000000000000000000")).wait();

  await (
    await lock.lock(
      "0x43e5fc23D4a7148c781B8A8aa74Fd70d2a558b5e",
      "718034000000000000000000"
    )
  ).wait();
  await (
    await lock.lock(
      "0x08BeFA0188Ba90b5A9C18b1b042E9d4ed955e713",
      "239345000000000000000000"
    )
  ).wait();
  await (
    await lock.lock(
      "0xeD09c46ee0Cf5842C8DE47921F191e22883eaCfa",
      "239345000000000000000000"
    )
  ).wait();

  const res = await pinJSONToIPFS(BURNLock.abi);

  // prettier-ignore
  process.stdout.write(`
  > BurningZombiesHonoraryERC721
    - Abi:     ${res.data.IpfsHash}\n`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
