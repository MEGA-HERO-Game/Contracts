
async function sleep(ms) {
    return new Promise((resolve) => {
        setTimeout(() => {
            resolve('');
        }, ms)
    });
}

async function main() {
    let paramsCommand = [];

    if (typeof(process.env.ConstructorArguments)=="undefined"){
        console.error('the constructor arguments env in not set');
        process.exit(1);
    } else{
        // Remove Spaces, quotes, etc
        paramsCommand = process.env.ConstructorArguments.replace(new RegExp(" ", 'g'),"").replace(new RegExp("'", 'g'),"").replace(new RegExp("\"", 'g'), "").split(",");
        if(paramsCommand.length !== 1) {
            console.error('the constructor arguments must 3 parm');
            process.exit(1);
        }
    }
    // Construction parameters
    const constructorArguments = [
        paramsCommand[0], // MetaWorldAddress
    ];

    console.log("constructorArguments info is as follows:");
    console.log("\tContract MetaWorldAddress:", constructorArguments[0]);


    const { deploy } = deployments;
    const [ deployer ] = await ethers.getSigners();
    console.log('deployer is ', deployer.address)

    // deploy
    const contract = await deploy('MetaWorldCollocation', {
       from: deployer.address,
       args: constructorArguments,
        log: true,
    }).then(s => ethers.getContractAt(s.abi, s.address, deployer));
    console.log('1. V1 MetaWorldCollocation has deployed at:', contract.address);
    console.log('    wait MetaWorldCollocation deployed, it will token one minute or more，Please be patient ');
    await contract.deployed();
    console.log('2. V1 MetaWorldCollocation has deployed');

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
    //     constructorArguments: constructorArguments
    // });
    //
    // console.log('2. V1 MetaWorldCollocation has verifyed');
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
