# Burning Zombies Contracts

**(EXPERIMENTAL) Use at your own risk.**

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

## Deployed Contracts

- BurningZombiesERC721: `TBA`
- BurningZombiesMarket: `TBA`
- NeonMonsters: `0x1b72CFde16E5a33a36eAAFbf2eb9CDEd02B09577`
- NeonMonstersMinters: `0x86796ff038D063a216D92167e53bA447E9Ce3C51`
