async function sleep(ms) {
    return new Promise((resolve) => {
        setTimeout(() => {
            resolve('');
        }, ms)
    });
}

let withdrawSigner = "0xC99F1314b093fB08514F2Fb8b213A2C4a537Fdf7";

async function main() {
    const { get } = deployments;
    const [ deployer ] = await ethers.getSigners();

    console.log('deployer is ', deployer.address)

    // Construction parameters
    const params = [
        withdrawSigner,
    ];

    const MetaWorld = await get('MetaWorld');
    let contract = await ethers.getContractAt(MetaWorld.abi, MetaWorld.address, deployer);

    // check deployed
    await contract.deployed();
    console.log('1. V1 meta world has deployed at:', contract.address);

    // verify
    await run("verify:verify", {
        address: contract.address,
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
