async function sleep(ms) {
    return new Promise((resolve) => {
        setTimeout(() => {
            resolve('');
        }, ms)
    });
}

async function main() {
    const { get } = deployments;
    const [ deployer ] = await ethers.getSigners();

    console.log('deployer is ', deployer.address)


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

    const Operator = await get('Operator');
    let operatorProxy = await ethers.getContractAt(Operator.abi, Operator.address, deployer);

    // check deployed
    await operatorProxy.deployed();
    console.log('1. V1 operator proxy has deployed at:', operatorProxy.address);

    // verify
    await run("verify:verify", {
        address: operatorProxy.address,
        constructorArguments: params
    });

    console.log('2. V1 Operator Proxy has verifyed');
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
