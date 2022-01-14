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

- BurningZombiesHonoraryERC721 `0x1B64380C5585DF25e784F08594D65b980A5489F0`
- PriceCalculator `0x149f78Ad023f8153750995e47000f4a8b445F2Ad`
- PaymentSplitter `0x19BD1dD6A19211E9D0Ed991B25a7ed4dCCA52b45`
- BurningZombiesERC721 `0x8B301E92Ed8565786F467c9D4655C8711c26AAfa`
- BurningZombiesMarket `0x5500Bc936Ce36324c235e6d3bf99083B618a5F99`
- BurningZombiesERC20 `0x9c4f88408f9f003Fb10f106E7A69989bB4f3452f`
- BURNLock `0x31D6B3aF022Fe664A99896CA45A794cD6C1A04dF`
