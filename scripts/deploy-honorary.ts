import { ethers } from "hardhat";
import BurningZombiesHonoraryERC721 from "../artifacts/contracts/BurningZombiesHonoraryERC721.sol/BurningZombiesHonoraryERC721.json";
import { pinJSONToIPFS } from "./utils"; // eslint-disable-line node/no-missing-import

async function main() {
  // const [owner] = await ethers.getSigners();

  const _ = await ethers.getContractFactory("BurningZombiesHonoraryERC721");
  const honorary = await _.deploy();
  await honorary.deployed();

  const honoraryABIResponse = await pinJSONToIPFS(
    BurningZombiesHonoraryERC721.abi
  );

  // prettier-ignore
  process.stdout.write(`
  > BurningZombiesHonoraryERC721
    - Address: ${honorary.address}
    - Abi:     ${honoraryABIResponse.data.IpfsHash}\n`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
