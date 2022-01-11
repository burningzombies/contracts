import { ethers } from "hardhat";
import Artifact from "../artifacts/contracts/BurningZombiesERC721.sol/BurningZombiesERC721.json";
import { pinJSONToIPFS } from "./utils"; // eslint-disable-line node/no-missing-import

const PRICE_CALCULATOR_ADDR = "";
const SPLITTER_ADDR = "";
const BASE_URI = "ipfs:///";

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

  const initialMint = await master.mintTokens(1, "", {
    value: "150000000000000000",
  });
  await initialMint.wait();
  const res = await pinJSONToIPFS(Artifact.abi);

  process.stdout.write(master.address + "\n");
  process.stdout.write(res.data.IpfsHash + "\n");
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
