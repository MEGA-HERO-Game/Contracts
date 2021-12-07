async function sleep(ms) {
    return new Promise((resolve) => {
        setTimeout(() => {
            resolve('');
        }, ms)
    });
}


async function main() {

    let paramsCommand = [];
    if (typeof(process.env.ConfigurationArguments)=="undefined"){
        console.error('the Configuration Argument env in not set');
        process.exit(1);
    } else{
        // Remove Spaces, quotes, etc
        paramsCommand = process.env.ConfigurationArguments.replace(new RegExp(" ", 'g'),"").replace(new RegExp("'", 'g'),"").replace(new RegExp("\"", 'g'), "").split(",");
        if(paramsCommand.length !== 2) {
            console.error('the Configuration Argument must 2 argument');
            process.exit(1);
        }
    }
    let metaWorldAddress = paramsCommand[0];
    let operatorAddress = paramsCommand[1];

    console.log("Configuration Argument is as follows:");
    console.log("\tmetaWorldAddress:", metaWorldAddress);
    console.log("\toperatorAddress:", operatorAddress);


    const [ deployer ] = await ethers.getSigners();
    console.log('deployer is ', deployer.address);

    // deployed check
    const MetaWorld = await ethers.getContractFactory("contracts/MetaWorld.sol:MetaWorld");
    const metaWorldToken = new ethers.Contract(metaWorldAddress, MetaWorld.interface, ethers.provider);
    await metaWorldToken.deployed();
    console.log('1. V1 meta world has deployed at:', metaWorldToken.address);

    // check and set the operator minter(the operator proxy contract address)
    let curOperator = await metaWorldToken.operator();
    if (curOperator !== operatorAddress) {
        console.log('   V1 meta world current operator address is:', curOperator);
        await  metaWorldToken.connect(deployer).setOperator(operatorAddress);
        console.log('   V1 meta world operator address set to:', operatorAddress);
    } else {
        console.log('   V1 meta world operator address already is:', operatorAddress);
    }

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
