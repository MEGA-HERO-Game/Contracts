async function sleep(ms) {
    return new Promise((resolve) => {
        setTimeout(() => {
            resolve('');
        }, ms)
    });
}

async function main() {

    let paramsCommand = [];
    if (typeof(process.env.VerifyArguments)=="undefined"){
        console.error('the Verify Arguments arguments env in not set');
        process.exit(1);
    } else{
        // Remove Spaces, quotes, etc
        paramsCommand = process.env.VerifyArguments.replace(new RegExp(" ", 'g'),"").replace(new RegExp("'", 'g'),"").replace(new RegExp("\"", 'g'), "").split(",");
        if(paramsCommand.length !== 2) {
            console.error('the constructor arguments must 2 param');
            process.exit(1);
        }
    }
    const metaWorldCollocationAddress = paramsCommand[0];
    // Construction parameters
    const constructorArguments = [
        paramsCommand[1], // MetaWorldAddress
    ];

    console.log("VerifyArguments info is as follows:");
    console.log("\tContract:", metaWorldCollocationAddress);
    console.log("\tContract MetaWorldAddress:", constructorArguments[1]);

    const [ deployer ] = await ethers.getSigners();
    console.log('deployer is ', deployer.address)

    // deployed check
    const MetaWorldCollocation = await ethers.getContractFactory("contracts/MetaWorldCollocation.sol:MetaWorldCollocation");
    const contract = new ethers.Contract(metaWorldCollocationAddress, MetaWorldCollocation.interface, ethers.provider);
    await contract.deployed();
    console.log('1. V1 MetaWorldCollocation has deployed at:', contract.address);

    // verify
    await run("verify:verify", {
        address: contract.address,
        constructorArguments: constructorArguments
    });

    console.log('2. V1 MetaWorldCollocation has verifyed');
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
