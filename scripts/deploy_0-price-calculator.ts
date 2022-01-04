import { ethers } from "hardhat";
import Artifact from "../artifacts/contracts/PriceCalculator.sol/PriceCalculator.json";
import { pinJSONToIPFS } from "./utils"; // eslint-disable-line node/no-missing-import

const main = async () => {
  const calculatorFactory = await ethers.getContractFactory("PriceCalculator");
  const calculator = await calculatorFactory.deploy();

  await calculator.deployed();

  const res = await pinJSONToIPFS(Artifact.abi);

  const setNemoTx = await calculator.setNeonMonsters(
    "0xff3C26091b08F43494fF02BDDBAA5efafA3f78a7"
  );
  await setNemoTx.wait();

  const setNemoMintersTx = await calculator.setNeonMonstersMinters(
    "0x8FD8c6dc93305D31A51dcDfaB276491bB02950AC"
  );
  await setNemoMintersTx.wait();

  process.stdout.write(calculator.address + "\n");
  process.stdout.write(res.data.IpfsHash + "\n");
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
