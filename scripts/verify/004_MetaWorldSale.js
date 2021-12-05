async function sleep(ms) {
    return new Promise((resolve) => {
        setTimeout(() => {
            resolve('');
        }, ms)
    });
}
// heco_test
//let metaWorld = "0xB71c4a9c6Bb7ae2379A20437596bec24A35931D2";
//let platformRecipient = "0xC99F1314b093fB08514F2Fb8b213A2C4a537Fdf7";
//let feeRatio = 20; //2%

// bsc_test
let metaWorld = "0xB71c4a9c6Bb7ae2379A20437596bec24A35931D2";
let platformRecipient = "0xC99F1314b093fB08514F2Fb8b213A2C4a537Fdf7";
let feeRatio = 20; //2%


async function main() {
    const { get } = deployments;
    const [ deployer ] = await ethers.getSigners();

    console.log('deployer is ', deployer.address)

    // Construction parameters
    const params = [
        metaWorld,
        platformRecipient,
        feeRatio,
    ];

    const MetaWorldSale = await get('MetaWorldSale');
    let contract = await ethers.getContractAt(MetaWorldSale.abi, MetaWorldSale.address, deployer);

    // check deployed
    await contract.deployed();
    console.log('1. V1 MetaWorldSale has deployed at:', contract.address);

    // verify
    await run("verify:verify", {
        address: contract.address,
        constructorArguments: params
    });

    console.log('2. V1 MetaWorldSale has verifyed');
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
