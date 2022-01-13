import { ethers } from "hardhat";
import Artifact from "../artifacts/contracts/PaymentSplitter.sol/PaymentSplitter.json";
import { pinJSONToIPFS } from "./utils"; // eslint-disable-line node/no-missing-import

const main = async () => {
  const splitterFactory = await ethers.getContractFactory("PaymentSplitter");
  const splitter = await splitterFactory.deploy(
    [
      "0xaBE94c96fd7C01Acaa312aeDC10e86828C65eC48", // l
      "0x43e5fc23D4a7148c781B8A8aa74Fd70d2a558b5e", // r
      "0xf97e31a178AEc1D84Cc05105f1b315240EDbD9D4", // a
      "0x08BeFA0188Ba90b5A9C18b1b042E9d4ed955e713", // h
      "0xeD09c46ee0Cf5842C8DE47921F191e22883eaCfa", // w
      "0x29aC43877A94A33198009716e90990231818EDE6", // m
    ],
    [30, 15, 15, 15, 15, 10]
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
