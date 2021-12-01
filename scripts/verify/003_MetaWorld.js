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

    // Construction parameters
    const params = [
    ];

    const MetaWorld = await get('MetaWorld');
    let metaWorldToken = await ethers.getContractAt(MetaWorld.abi, MetaWorld.address, deployer);

    // check deployed
    await metaWorldToken.deployed();
    console.log('1. V1 meta world has deployed at:', mpToken.address);

    // verify
    await run("verify:verify", {
        address: metaWorldToken.address,
        constructorArguments: params
    });

    console.log('2. V1 meta world has verifyed');
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
