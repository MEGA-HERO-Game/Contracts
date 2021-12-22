const {int} = require("hardhat/internal/core/params/argumentTypes");

async function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve('');
    }, ms)
  });
}
// heco_testnet
let metaWorld = "0xB71c4a9c6Bb7ae2379A20437596bec24A35931D2";
let platformRecipient = "0xC99F1314b093fB08514F2Fb8b213A2C4a537Fdf7";
let feeRatio = 20; //2%

const func = async ({ getNamedAccounts, deployments, network }) => {
  const { AddressZero } = ethers.constants;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  console.log('deployer is ', deployer)

  const options = { from: deployer };

  // Construction parameters
  const params = [
    metaWorld,
    platformRecipient,
    feeRatio,
  ];

  const contract = await deploy('MetaWorldSale', {...options, args: params});

  if (network.live) {
    signer = await ethers.getNamedSigner('deployer');
  } else {
    await network.provider.request({ method: "hardhat_impersonateAccount", params: [ signer ]});
    signer = await ethers.getSigner(signer);
  }

  console.log('1. V1 MetaWorldSale has deployed at:', contract.address);

  console.log('    wait MetaWorldSale deployed, it will token one minute or more，Please be patient ');


  let waitTime = 60; // 60 s wait scan indexed
  for (var i = 0; i< waitTime; i++){
    await sleep(1000);
    if ( i%3 == 0) {
      console.log('  wait deploy completed after', waitTime - i, " s");
    }
  }

  verifyAddress = contract.address;
  await run("verify:verify", {
    address: verifyAddress,
    constructorArguments: params
  });
  console.log('1. V1 MetaWorldSale has verifyed');

  return network.live;
};

func.id = 'deploy_MetaWorldSale_v1';
module.exports = func;
