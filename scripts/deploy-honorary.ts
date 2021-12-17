import { Contract } from "ethers";
import { ethers } from "hardhat";
import axios from "axios";
import BurningZombiesHonoraryERC721 from "../artifacts/contracts/BurningZombiesHonoraryERC721.sol/BurningZombiesHonoraryERC721.json";

const pinJSONToIPFS = async (
  pinataApiKey: string,
  pinataSecretApiKey: string,
  JSONBody: any
) => {
  const url = `https://api.pinata.cloud/pinning/pinJSONToIPFS`;

  const response = await axios.post(url, JSONBody, {
    headers: {
      pinata_api_key: pinataApiKey,
      pinata_secret_api_key: pinataSecretApiKey,
    },
  });
  return response;
};

async function main() {
  const [owner] = await ethers.getSigners();

  const _ = await ethers.getContractFactory("BurningZombiesHonoraryERC721");
  const honorary = await _.deploy();
  await honorary.deployed();

  const honoraryABIResponse = await pinJSONToIPFS(
    process.env.PINATA_API_KEY as string,
    process.env.PINATA_API_SECRET as string,
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
