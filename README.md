# MetaWorld Contract

## install depends
npm install
## compile the contract
compile the contract use this command
```bash
npx hardhat --network <network> compile
```
such as use the heco network compile the contracts
```bash
npx hardhat --network heco compile
```

## test contract
```
npx hardhat --network hardhat compile
npx hardhat --network hardhat test 
```

## deploy the contract
use the deploy script and constructor arguments env deploy the contract 
such as use this command deploy the meta world contract 
```bash
env ConstructorArguments="<name>,<symbol>,<withdrawSigner>" npx hardhat --network <network> run scripts/deploy/003_MetaWorld.js
```
such as use the heco network deploy the meta world contract
```bash
env ConstructorArguments="MetaWorld,MW,0xC99F1314b093fB08514F2Fb8b213A2C4a537Fdf7" npx hardhat --network heco run scripts/deploy/003_MetaWorld.js
```
## verify the contract
use the verify script and verify arguments env verify the contract
such as use this command verify the meta world contract
```bash
env VerifyArguments="<metaWorld contract address>,<name>,<symbol>,<withdrawSigner>" npx hardhat --network <network> run scripts/verify/003_MetaWorld.js
```
such as use the heco network verify the meta world contract
```bash
env VerifyArguments="0x9f6320c12d2Ae46122e5982089b8Fd6Ce6bd0f86,MetaWorld,MW,0xC99F1314b093fB08514F2Fb8b213A2C4a537Fdf7" npx hardhat --network heco run scripts/verify/003_MetaWorld.js
```

## configuration the contract
use the configuration script and configuration arguments env configuration the contract
such as use this command configuration the meta world contract
```bash
env ConfigurationArguments="<metaWorld contract address>,<operatorAddress>" npx hardhat --network <network> run scripts/configuration/003_MetaWorld.js
```
such as use the heco network verify the meta world contract
```bash
env ConfigurationArguments="0x9f6320c12d2Ae46122e5982089b8Fd6Ce6bd0f86,0xC99F1314b093fB08514F2Fb8b213A2C4a537Fdf7" npx hardhat --network heco run scripts/configuration/003_MetaWorld.js
```

## rinkeby testnet
### deploy the contract
npx hardhat --network heco_testnet deploy
### verify the contract
npx hardhat verify --network heco_testnet <contract address>

## Contract 
### heco test net deploy
```
npx hardhat --network heco_testnet compile
npx hardhat --network heco_testnet run scripts/deploy/003_MetaWorld.js
npx hardhat --network heco_testnet run scripts/configuration/003_MetaWorld.js
npx hardhat --network heco_testnet run scripts/deploy/005_MetaWorldCollocation.js
```
### bsc test net deploy
```
npx hardhat --network bsc_testnet compile

npx hardhat --network bsc_testnet run scripts/deploy/003_MetaWorld.js
npx hardhat --network bsc_testnet run scripts/verify/003_MetaWorld.js
npx hardhat --network bsc_testnet run scripts/configuration/003_MetaWorld.js

npx hardhat --network bsc_testnet run scripts/deploy/004_MetaWorldSale.js
npx hardhat --network bsc_testnet run scripts/verify/004_MetaWorldSale.js
npx hardhat --network bsc_testnet run scripts/configuration/004_MetaWorldSale.js
```
## TODO:

