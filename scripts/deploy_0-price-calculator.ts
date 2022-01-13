import { ethers } from "hardhat";
import Artifact from "../artifacts/contracts/PriceCalculator.sol/PriceCalculator.json";
import { pinJSONToIPFS } from "./utils"; // eslint-disable-line node/no-missing-import

const main = async () => {
  const calculatorFactory = await ethers.getContractFactory("PriceCalculator");
  const calculator = await calculatorFactory.deploy();

  await calculator.deployed();
  process.stdout.write(calculator.address + "\n");

  const res = await pinJSONToIPFS(Artifact.abi);

  const setNemoMintersTx = await calculator.setNeonMonstersMinters(
    "0x86796ff038D063a216D92167e53bA447E9Ce3C51"
  );
  await setNemoMintersTx.wait();

  const setNemoTx = await calculator.addERC721Token(
    "0x1b72CFde16E5a33a36eAAFbf2eb9CDEd02B09577",
    1
  );
  await setNemoTx.wait();

  process.stdout.write(calculator.address + "\n");
  process.stdout.write(res.data.IpfsHash + "\n");
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
