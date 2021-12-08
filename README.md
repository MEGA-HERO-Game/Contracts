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
env ConfigurationArguments="<metaWorld contract address>,<operatorAddress>,<OwnerAddress>" npx hardhat --network <network> run scripts/configuration/003_MetaWorld.js
```
such as use the heco network verify the meta world contract
```bash
env ConfigurationArguments="0x9f6320c12d2Ae46122e5982089b8Fd6Ce6bd0f86,0xC99F1314b093fB08514F2Fb8b213A2C4a537Fdf7,0xC99F1314b093fB08514F2Fb8b213A2C4a537Fdf7" npx hardhat --network heco run scripts/configuration/003_MetaWorld.js
```

## Contract Deploy Detail
### MegaHero Heco MainNet Deploy
```bash
# ConstructorArguments="<name>,<symbol>,<withdrawSigner>"
env ConstructorArguments="MegaHero,MH,0x9Dfb975579e4D004eFe2df96F6552BB570F662f8" npx hardhat --network heco run scripts/deploy/003_MetaWorld.js
# VerifyArguments="<metaWorld contract address>,<name>,<symbol>,<withdrawSigner>"
env VerifyArguments="0xB71c4a9c6Bb7ae2379A20437596bec24A35931D2,MegaHero,MH,0x9Dfb975579e4D004eFe2df96F6552BB570F662f8" npx hardhat --network heco run scripts/verify/003_MetaWorld.js
# ConfigurationArguments="<metaWorld contract address>,,<operatorAddress>,<OwnerAddress>"
env ConfigurationArguments="0xB71c4a9c6Bb7ae2379A20437596bec24A35931D2,0x9AB363AEE708075b0E19Bf0C80740B68AC493C4B,0xac3b316bb782cb4587A7FD2522e0161E702BA579" npx hardhat --network heco run scripts/configuration/003_MetaWorld.js

```