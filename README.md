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
npx hardhat --network heco_testnet run scripts/deploy/004_OperatorProxy.js
npx hardhat --network heco_testnet run scripts/configuration/003_MetaWorld.js
```
### single test contract
```
npx hardhat test test/test/003_MetaWorld.js
```

## TODO:

