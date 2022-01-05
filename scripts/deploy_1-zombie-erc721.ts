import { ethers } from "hardhat";
import Artifact from "../artifacts/contracts/BurningZombiesERC721.sol/BurningZombiesERC721.json";
import { pinJSONToIPFS } from "./utils"; // eslint-disable-line node/no-missing-import

const PRICE_CALCULATOR_ADDR = "0x7D5B2e34381A955ac80e925A4fBba356194ed194";
const SPLITTER_ADDR = "0xE70b9a060785daE17bF8A9f3CdA200e2c7267EBa";
const BASE_URI = "ipfs://QmWuFvirTSvcUBRKUugKtajTruNxMGrg9m1defTPftjoGk/";

const main = async () => {
  const masterFactory = await ethers.getContractFactory("BurningZombiesERC721");
  const master = await masterFactory.deploy(
    SPLITTER_ADDR,
    BASE_URI,
    Math.floor(new Date().getTime() / 1000),
    43500
  );

  await master.deployed();

  const refTx = await master.setReflectionDynamics(
    336,
    30,
    0,
    ethers.utils.parseUnits("1", 18),
    0
  );
  await refTx.wait();

  const priceTx = await master.setPriceCalculator(PRICE_CALCULATOR_ADDR);
  await priceTx.wait();

  const provenance = await master.setProvenance(
    "079c5bf3139075627e7c740b6bf78fd158bc260eb5cdba83b1a2c2e4026c191c"
  );
  await provenance.wait();

  const res = await pinJSONToIPFS(Artifact.abi);

  process.stdout.write(master.address + "\n");
  process.stdout.write(res.data.IpfsHash + "\n");
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
