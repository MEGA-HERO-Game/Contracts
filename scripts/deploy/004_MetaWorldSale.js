
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
    const { deploy } = deployments;
    const [ deployer ] = await ethers.getSigners();

    console.log('deployer is ', deployer.address)

    // Construction parameters
    const params = [
        metaWorld,
        platformRecipient,
        feeRatio,
    ];

    // deploy
    const contract = await deploy('MetaWorldSale', {
       from: deployer.address,
       args: params,
        log: true,
    }).then(s => ethers.getContractAt(s.abi, s.address, deployer));

    console.log('1. V1 MetaWorldSale has deployed at:', contract.address);

    console.log('    wait MetaWorldSale deployed, it will token one minute or more，Please be patient ');

    await contract.deployed();

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
    //     address: contract.address,
    //     constructorArguments: params
    // });
    //
    // console.log('2. V1 MetaWorldSale has verifyed');
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
