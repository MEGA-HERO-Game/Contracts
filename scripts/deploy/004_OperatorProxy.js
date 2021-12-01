
async function sleep(ms) {
    return new Promise((resolve) => {
        setTimeout(() => {
            resolve('');
        }, ms)
    });
}

async function main() {
    const { deploy } = deployments;
    const [ deployer ] = await ethers.getSigners();

    console.log('deployer is ', deployer.address)


    let metaWorld = "0xB71c4a9c6Bb7ae2379A20437596bec24A35931D2";
    let oldMPNFT = "0xB71c4a9c6Bb7ae2379A20437596bec24A35931D2";
    let usdt = "0xE65673Ce68C0caaBEF36e5301c7A7654E630a2C6";
    let invitationSigner = "0x796d833c1c6fF56216d070A61Dd42897Af1ee1A7";
    let ibox = "0x87b59F4E3129E89bA53333028945625a0eE46C66";
    let withdrawSigner = "0xC99F1314b093fB08514F2Fb8b213A2C4a537Fdf7";
    // Construction parameters
    const params = [
        metaWorld,
        oldMPNFT,
        usdt,
        invitationSigner,
        ibox,
        withdrawSigner,
    ];

    // deploy
    const operatorProxy = await deploy('Operator', {
       from: deployer.address,
       args: params,
        log: true,
    }).then(s => ethers.getContractAt(s.abi, s.address, deployer));

    console.log('1. V1 Operator has deployed at:', operatorProxy.address);

    console.log('    wait Operator deployed, it will token one minute or more，Please be patient ');

    await operatorProxy.deployed();

    // let waitTime = 30; // 30 s wait scan indexed
    // for (var i = 0; i< waitTime; i++){
    //     await sleep(1000);
    //     if ( i%3 == 0) {
    //         console.log('  wait deploy completed after', waitTime - i, " s");
    //     }
    // }
    //
    // // verify
    // await run("verify:verify", {
    //     address: operatorProxy.address,
    //     constructorArguments: params
    // });
    //
    // console.log('2. V1 Operator has verifyed');
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
