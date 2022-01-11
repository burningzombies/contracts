import { ethers } from "ethers";
import holders from "./holders.json";
import { MerkleTree } from "merkletreejs";
import keccak256 from "keccak256";
// import fs from "fs";

const main = async () => {
  const accounts = Object.entries(holders);
  const elements = accounts.map((x) =>
    ethers.utils.solidityKeccak256(["address", "uint256"], [x[0], x[1]])
  );

  const merkleTree = new MerkleTree(elements, keccak256, { sort: true });
  // const merkleRoot = merkleTree.getHexRoot();

  const data = [];

  for (let i = 0; elements.length > i; i++) {
    const proof = merkleTree.getHexProof(elements[i]);
    data.push({
      owner: accounts[i][0].toLowerCase(),
      amount: accounts[i][1],
      proof: proof,
    });
  }

  // fs.writeFileSync(
  //  "processed.json",
  //  JSON.stringify(data)
  // );
};

main();
