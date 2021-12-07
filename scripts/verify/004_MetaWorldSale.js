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
        console.error('the Verify Arguments env in not set');
        process.exit(1);
    } else{
        // Remove Spaces, quotes, etc
        paramsCommand = process.env.VerifyArguments.replace(new RegExp(" ", 'g'),"").replace(new RegExp("'", 'g'),"").replace(new RegExp("\"", 'g'), "").split(",");
        if(paramsCommand.length !== 4) {
            console.error('the Verify Arguments must 4 param');
            process.exit(1);
        }
    }
    const metaWorldSaleAddress =  paramsCommand[0];

    // Construction parameters
    const constructorArguments = [
        paramsCommand[1], // MetaWorldAddress
        paramsCommand[2], // PlatformRecipient
        paramsCommand[3], // FeeRatio
    ];

    console.log("VerifyArguments info is as follows:");
    console.log("\tContract Address:", metaWorldSaleAddress);
    console.log("\tContract MetaWorldAddress:", constructorArguments[0]);
    console.log("\tContract PlatformRecipient:", constructorArguments[1]);
    console.log("\tContract FeeRatio:", constructorArguments[2]);

    const { get } = deployments;
    const [ deployer ] = await ethers.getSigners();
    console.log('deployer is ', deployer.address)


    // deployed check
    const MetaWorldSale = await ethers.getContractFactory("contracts/MetaWorldSale.sol:MetaWorldSale");
    const contract = new ethers.Contract(metaWorldSaleAddress, MetaWorldSale.interface, ethers.provider);
    await contract.deployed();
    console.log('1. V1 metaWorld has deployed at:', contract.address);

    // verify
    await run("verify:verify", {
        address: contract.address,
        constructorArguments: constructorArguments
    });

    console.log('2. V1 MetaWorldSale has verifyed');
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
