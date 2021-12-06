# Burning Zombies Contracts

This repo contains all of the smart contracts used to run Burning Zombies.

Try running some of the following tasks:

```shell
npm run lint:sol              # Linter for *.sol files
npm run lint:js               # Linter for js,ts files
npm run test                  # Run hardhat test
npx hardhat                   # Compile solidity

# Deploy contracts
npx hardhat run --network <BLOCKCHAIN> scripts/deploy.ts

# Verify contracts
npx hardhat verify --network <BLOCKCHAIN> <DEPLOYED_CONTRACT_ADDRESS> <ARGUMENTS>
```
