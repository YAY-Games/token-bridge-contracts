# Token bridge contracts

Based on https://github.com/binance-chain/eth-bsc-swap-contracts

- Language: Solidity v0.6.12

- Project framework: hardhat + truffle / web3

- Nodejs: v14.17.0

## Overview

Token bridge contracts are responsible for registering swap pairs and swapping assets between BSC and AVAX.

![](./assets/eth-bsc-swap.png)

### Register swap pair

1. Owner register swap pair for erc20 token on BSC via BSCSwapAgent(`createSwapPair`) if token is not registered.
2. Swap service will monitor the `SwapPairRegister` event and create swap pair on BSC: 

    1. create an BEP20 token on BSC
    2. record the relation between bep20 token and erc20 token.

### Swap from BSC to AVAX

Once swap pair is registered, users can swap tokens from BSC to AVAX.

1. Users call `swapBSC2AVAX` via BSCSwapAgent and specify erc20 token address, amount and swap fee.
2. Swap service will monitor the `SwapStarted` event and call `fillBSC2AVAXSwap` via AVAXSwapAgent to mint corresponding erc20 tokens to the same address that initiate the swap.

### Swap from AVAX to BSC

Once swap pair is registered, users can swap tokens from BSC to AVAX.

1. Users call `swapAVAX2BSC` via AVAXSwapAgent and specify erc20 token address, amount and swap fee.
2. Swap service will monitor the `SwapStarted` event and call `fillAVAX2BSCSwap` via AVAXSwapAgent to mint corresponding erc20 tokens to the same address that initiate the swap.

### Deployed contracts

- BSC: https://bscscan.com/address/0x320f93Cd60e85F91289533FE45D031A35426c5D8/
- AVAX: https://cchain.explorer.avax.network/address/0x038Cf43b3292cb3B43e09722302D68798480e6e6/

## Installation & Usage

1. Install packages
```
npm i --save-dev
```

2. Build project
```
npm run build
```

### Testing

```
npm test
```

### Run linter

```
npm run lint
```

### Deploy

1. Edit network in ```hardhat.config.js``` ([docs](https://hardhat.org/config/))

2. Setup environment variables:
```
cp .env.example .env
// then edit .env
```

3. Run command for BSC network:
```
npx hardhat run scripts/bsc-initial-deploy.js --network <network name>
```

4. Run command for AVAX network:
```
npx hardhat run scripts/avax-initial-deploy.js --network <network name>
```

