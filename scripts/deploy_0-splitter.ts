import { ethers } from "hardhat";
import Artifact from "../artifacts/contracts/PaymentSplitter.sol/PaymentSplitter.json";
import { pinJSONToIPFS } from "./utils"; // eslint-disable-line node/no-missing-import

const main = async () => {
  const [owner] = await ethers.getSigners();

  const splitterFactory = await ethers.getContractFactory("PaymentSplitter");
  const splitter = await splitterFactory.deploy(
    [await owner.getAddress()],
    [100]
  );

  await splitter.deployed();

  const res = await pinJSONToIPFS(Artifact.abi);

  process.stdout.write(splitter.address + "\n");
  process.stdout.write(res.data.IpfsHash + "\n");
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
