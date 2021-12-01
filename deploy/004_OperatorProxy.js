const {int} = require("hardhat/internal/core/params/argumentTypes");

async function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve('');
    }, ms)
  });
}

const func = async ({ getNamedAccounts, deployments, network }) => {
  const { AddressZero } = ethers.constants;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  console.log('deployer is ', deployer)

  const options = { from: deployer };

  let mPNFT = "0xB71c4a9c6Bb7ae2379A20437596bec24A35931D2";
  let oldMPNFT = "0xB71c4a9c6Bb7ae2379A20437596bec24A35931D2";
  let usdt = "0xE65673Ce68C0caaBEF36e5301c7A7654E630a2C6";
  let invitationSigner = "0x796d833c1c6fF56216d070A61Dd42897Af1ee1A7";
  let ibox = "0x87b59F4E3129E89bA53333028945625a0eE46C66";
  let withdrawSigner = "0xC99F1314b093fB08514F2Fb8b213A2C4a537Fdf7";
  // Construction parameters
  const params = [
    mPNFT,
    oldMPNFT,
    usdt,
    invitationSigner,
    ibox,
    withdrawSigner,
  ];

  const mpToken = await deploy('Operator', {...options, args: params});

  if (network.live) {
    signer = await ethers.getNamedSigner('deployer');
  } else {
    await network.provider.request({ method: "hardhat_impersonateAccount", params: [ signer ]});
    signer = await ethers.getSigner(signer);
  }

  console.log('1. V1 Operator Proxy has deployed at:', mpToken.address);

  console.log('    wait Operator Proxy deployed, it will token one minute or more，Please be patient ');


  let waitTime = 60; // 60 s wait scan indexed
  for (var i = 0; i< waitTime; i++){
    await sleep(1000);
    if ( i%3 == 0) {
      console.log('  wait deploy completed after', waitTime - i, " s");
    }
  }

  verifyAddress = mpToken.address;
  await run("verify:verify", {
    address: verifyAddress,
    constructorArguments: params
  });
  console.log('1. V1 Operator Proxy has verifyed');

  return network.live;
};

func.id = 'deploy_OperatorProxy_v1';
module.exports = func;
