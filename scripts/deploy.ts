import { Contract } from "ethers";
import { ethers } from "hardhat";
import axios from "axios";
import PaymentSplitterArtifact from "../artifacts/contracts/PaymentSplitter.sol/PaymentSplitter.json";
import BurningZombiesERC721Artifact from "../artifacts/contracts/BurningZombiesERC721.sol/BurningZombiesERC721.json";
import BurningZombiesMarketArtifact from "../artifacts/contracts/BurningZombiesMarket.sol/BurningZombiesMarket.json";

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

  // Deploy splitter contract
  const splitterFactory = await ethers.getContractFactory("PaymentSplitter");
  const splitter = await splitterFactory.deploy(
    [await owner.getAddress()],
    [100]
  );
  await splitter.deployed();
  process.stdout.write(`\r  > PaymentSplitter deployed.`);

  // Deploy master
  const burningZombiesFactory = await ethers.getContractFactory(
    "BurningZombiesERC721"
  );
  const burningZombies: Contract = await burningZombiesFactory.deploy(
    splitter.address,
    "ipfs://metadata/",
    Math.floor(new Date().getTime() / 1000),
    60 * 60 * 24 * 7
  );
  await burningZombies.deployed();
  process.stdout.write(`\r  > BurningZombiesERC721 deployed.`);

  const setNemoTx = await burningZombies.setNeonMonstersContract(
    "0x1b72CFde16E5a33a36eAAFbf2eb9CDEd02B09577"
  );
  const setNemoMockTx = await burningZombies.setNeonMonstersMintersContract(
    "0x86796ff038D063a216D92167e53bA447E9Ce3C51"
  );

  await Promise.all([setNemoTx, setNemoMockTx]);
  process.stdout.write(`\r  > Neon Monsters contracts defined.`);

  const BURNING_ZOMBIES_MARKET = await ethers.getContractFactory(
    "BurningZombiesMarket"
  );
  const burningZombiesMarket: Contract = await BURNING_ZOMBIES_MARKET.deploy(
    burningZombies.address,
    3,
    5,
    12
  );
  await burningZombiesMarket.deployed();
  process.stdout.write(`\r  > BurningZombiesMarket deployed.`);

  const provenance = await burningZombies.setProvenance(
    "c6e8903ba59af7399d56cff6abed253a92be241813965b41c5a98b119e6cb7ee"
  );
  await provenance.wait();
  process.stdout.write(`\r  > Provenance defined.`);

  const paymentSplitterAbiResponse = await pinJSONToIPFS(
    process.env.PINATA_API_KEY as string,
    process.env.PINATA_API_SECRET as string,
    PaymentSplitterArtifact.abi
  );
  process.stdout.write(`\r  > PaymentSplitter ABI uploaded to ipfs.`);

  const burningZombiesErc721AbiResponse = await pinJSONToIPFS(
    process.env.PINATA_API_KEY as string,
    process.env.PINATA_API_SECRET as string,
    BurningZombiesERC721Artifact.abi
  );
  process.stdout.write(`\r  > BurningZombiesERC721 ABI uploaded to ipfs.`);

  const burningZombiesMarketAbiResponse = await pinJSONToIPFS(
    process.env.PINATA_API_KEY as string,
    process.env.PINATA_API_SECRET as string,
    BurningZombiesMarketArtifact.abi
  );
  process.stdout.write(`\r  > BurningZombiesMarket ABI uploaded to ipfs.`);

  // prettier-ignore
  process.stdout.write(`\n
  > PaymentSplitter
     - Address: ${splitter.address}
     - Abi:     ${paymentSplitterAbiResponse.data.IpfsHash}
  
  > BurningZombiesERC721
    - Address: ${burningZombies.address}
    - Abi:     ${burningZombiesErc721AbiResponse.data.IpfsHash}

  > BurningZombiesMarket
    - Address: ${burningZombiesMarket.address}
    - Abi:     ${burningZombiesMarketAbiResponse.data.IpfsHash}\n`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
