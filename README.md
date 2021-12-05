# Contract

## install depends
npm install

## rinkeby testnet
### compile the contract
npx hardhat --network heco_testnet compile
### deploy the contract
npx hardhat --network heco_testnet deploy
### verify the contract
npx hardhat verify --network heco_testnet <contract address>



### single deploy contract 
```
npx hardhat --network heco_testnet run scripts/deploy/003_MetaWorld.js
npx hardhat --network heco_testnet run scripts/configuration/003_MetaWorld.js
```
### single test contract
```
npx hardhat test test/test/003_MetaWorld.js
```

### bsc test net deploy
```
npx hardhat --network bsc_testnet compile

npx hardhat --network bsc_testnet run scripts/deploy/003_MetaWorld.js
npx hardhat --network bsc_testnet run scripts/verify/003_MetaWorld.js
npx hardhat --network bsc_testnet run scripts/configuration/003_MetaWorld.js

npx hardhat --network bsc_testnet run scripts/deploy/004_MetaWorldSale.js
npx hardhat --network bsc_testnet run scripts/verify/003_MetaWorldSeal.js
npx hardhat --network bsc_testnet run scripts/configuration/003_MetaWorldSeal.js
```

## TODO:

