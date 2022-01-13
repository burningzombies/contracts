import { ethers } from "hardhat";
import Artifact from "../artifacts/contracts/BurningZombiesERC721.sol/BurningZombiesERC721.json";
import { pinJSONToIPFS } from "./utils"; // eslint-disable-line node/no-missing-import

const PRICE_CALCULATOR_ADDR = "0x149f78Ad023f8153750995e47000f4a8b445F2Ad";
const SPLITTER_ADDR = "0x19BD1dD6A19211E9D0Ed991B25a7ed4dCCA52b45";
const BASE_URI = "ipfs://iQmUzSKETzrQRrwMYsdgWNUqz72MYx2YA3GvrvP2YeeAq6Y/";

const main = async () => {
  const masterFactory = await ethers.getContractFactory("BurningZombiesERC721");
  const master = await masterFactory.deploy(
    SPLITTER_ADDR,
    BASE_URI,
    1643760000,
    0
  );

  await master.deployed();
  console.log(master.address);

  const priceTx = await master.setPriceCalculator(PRICE_CALCULATOR_ADDR);
  await priceTx.wait();

  // const provenance = await master.setProvenance(
  //   ""
  // );
  // await provenance.wait();

  const initialMint = await master.mintTokens(
    15,
    "0xa7Cbe4B731459CC765c311b9B68f03eD1f1AF8be",
    {
      value: "150000000000000000",
    }
  );
  await initialMint.wait();
  const res = await pinJSONToIPFS(Artifact.abi);

  process.stdout.write(master.address + "\n");
  process.stdout.write(res.data.IpfsHash + "\n");
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
