import { ethers } from "hardhat";
import Artifact from "../artifacts/contracts/BurningZombiesERC721.sol/BurningZombiesERC721.json";
import { pinJSONToIPFS } from "./utils"; // eslint-disable-line node/no-missing-import

const PRICE_CALCULATOR_ADDR = "0xAf83EEd096279c4111Cdb335238b3f4c2362F285";
const SPLITTER_ADDR = "0xb8d4AF5Ec981B8188a9aCEd3c4c1caE57242FDa8";
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

  const priceTx = await master.setPriceCalculator(PRICE_CALCULATOR_ADDR);
  await priceTx.wait();

  // const provenance = await master.setProvenance(
  //   ""
  // );
  // await provenance.wait();

  const initialMint = await master.mintTokens(
    1,
    "0x12F0528E4ab1EafD07404C63E0Fb19D7eC784988",
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
