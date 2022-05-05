# V3 Contracts [![Solidity CI](https://github.com/maticnetwork/v3-contracts/actions/workflows/ci.yml/badge.svg)](https://github.com/maticnetwork/v3-contracts/actions/workflows/ci.yml) [![Coverage Status](https://coveralls.io/repos/github/maticnetwork/v3-contracts/badge.svg?branch=main&t=ZTUm69)](https://coveralls.io/github/maticnetwork/v3-contracts?branch=main)

This is the primary repository for all contracts that are utilized for Polygon PoS V3.

## Installation

```bash
git clone git@github.com:maticnetwork/v3-contracts.git

nvm use # if you have `nvm` installed and want to use it, else skip if using other node instances

npm install
```

## Compile contracts

```bash
npx hardhat compile --show-stack-traces
```

`hardhat-ts` automatically generates typings for you after compilation, to use in tests and scripts. You can import them like: `import { ... } from "../typechain";`

## Running tests

```bash
npx hardhat test
```

Tests have gas reporting enabled by default, you can disable them from `hardhat.config.ts`

## Linting

```bash
npm run lint # runs all linters at once

npm run lint:sol # only runs solhint and prettier
npm run lint:ts # only runs prettier and eslint
```

## Check coverage

```bash
npx hardhat coverage

# or

npm run coverage
```

## Run slither

First, install slither by following the instructions [here](https://github.com/crytic/slither#how-to-install).
Then, run:

```bash
slither .

# or

npm run slither
```
