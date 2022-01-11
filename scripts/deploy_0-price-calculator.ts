import { ethers } from "hardhat";
import Artifact from "../artifacts/contracts/PriceCalculator.sol/PriceCalculator.json";
import { pinJSONToIPFS } from "./utils"; // eslint-disable-line node/no-missing-import

const main = async () => {
  const calculatorFactory = await ethers.getContractFactory("PriceCalculator");
  const calculator = await calculatorFactory.deploy();

  await calculator.deployed();

  const res = await pinJSONToIPFS(Artifact.abi);

  const setNemoMintersTx = await calculator.setNeonMonstersMinters("");
  await setNemoMintersTx.wait();

  const setNemoTx = await calculator.addERC721Token("", 1);
  await setNemoTx.wait();

  process.stdout.write(calculator.address + "\n");
  process.stdout.write(res.data.IpfsHash + "\n");
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
