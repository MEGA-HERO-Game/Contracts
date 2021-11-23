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

    const MP = await get('MP');
    let mpToken = await ethers.getContractAt(MP.abi, MP.address, deployer);

    // check deployed
    await mpToken.deployed();
    console.log('1. V1 MP has deployed at:', mpToken.address);

    // verify
    await run("verify:verify", {
        address: mpToken.address,
        constructorArguments: params
    });

    console.log('2. V1 MP has verifyed');
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
