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
        console.error('the Verify Arguments  env in not set');
        process.exit(1);
    } else{
        // Remove Spaces, quotes, etc
        paramsCommand = process.env.VerifyArguments.replace(new RegExp(" ", 'g'),"").replace(new RegExp("'", 'g'),"").replace(new RegExp("\"", 'g'), "").split(",");
        if(paramsCommand.length !== 4) {
            console.error('the Verify Arguments must 4 param');
            process.exit(1);
        }
    }

    const metaWorldAddress =  paramsCommand[0];

    // Construction parameters
    const constructorArguments = [
        paramsCommand[1], // Contract Name
        paramsCommand[2], // Contract Symbol
        paramsCommand[3], //  withdrawSigner
    ];

    console.log("VerifyArguments info is as follows:");
    console.log("\tContract Address:", metaWorldAddress);
    console.log("\tContract Name:", constructorArguments[0]);
    console.log("\tContract Symbol:", constructorArguments[1]);
    console.log("\tContract withdrawSigner:", constructorArguments[2]);

    const [ deployer ] = await ethers.getSigners();
    console.log('deployer is ', deployer.address);

    // deployed check
    const MetaWorld = await ethers.getContractFactory("contracts/MetaWorld.sol:MetaWorld");
    const contract = new ethers.Contract(metaWorldAddress, MetaWorld.interface, ethers.provider);
    await contract.deployed();
    console.log('1. V1 metaWorld has deployed at:', contract.address);

    // verify
    await run("verify:verify", {
        address: contract.address,
        constructorArguments: constructorArguments
    });

    console.log('2. V1 meta world has verifyed');
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
