async function sleep(ms) {
    return new Promise((resolve) => {
        setTimeout(() => {
            resolve('');
        }, ms)
    });
}
// heco_test
let metaWorld = "0x431cF2d9cdb78C9324Ae72d3567a951577658e16";

// bsc_test
// let metaWorld = "0xB71c4a9c6Bb7ae2379A20437596bec24A35931D2";


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

    const MetaWorldCollocation = await get('MetaWorldCollocation');
    let contract = await ethers.getContractAt(MetaWorldCollocation.abi, MetaWorldCollocation.address, deployer);

    // check deployed
    await contract.deployed();
    console.log('1. V1 MetaWorldCollocation has deployed at:', contract.address);

    // verify
    await run("verify:verify", {
        address: contract.address,
        constructorArguments: params
    });

    console.log('2. V1 MetaWorldCollocation has verifyed');
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
