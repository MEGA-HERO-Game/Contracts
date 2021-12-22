
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
        console.error('the Configuration Argumnet env in not set');
        process.exit(1);
    } else{
        // Remove Spaces, quotes, etc
        paramsCommand = process.env.ConfigurationArguments.replace(new RegExp(" ", 'g'),"").replace(new RegExp("'", 'g'),"").replace(new RegExp("\"", 'g'), "").split(",");
        if(paramsCommand.length !== 3) {
            console.error('the Configuration Argumnet must 3 argument');
            process.exit(1);
        }
    }
    let metaWorldSaleAddress = paramsCommand[0];
    let usdtAddress = paramsCommand[1];
    let ownerAddress = paramsCommand[2];

    console.log("ConfigurationArgumnet info is as follows:");
    console.log("\tmetaWorldSaleAddress:", metaWorldSaleAddress);
    console.log("\tusdtAddress:", usdtAddress);
    console.log("\townerAddress:", ownerAddress);


    const [ deployer ] = await ethers.getSigners();
    console.log('deployer is ', deployer.address)

    // deployed check
    const MetaWorldSale = await ethers.getContractFactory("contracts/MetaWorldSale.sol:MetaWorldSale");
    const contract = new ethers.Contract(metaWorldSaleAddress, MetaWorldSale.interface, ethers.provider);
    await contract.deployed();
    console.log('1. V1 MetaWorldSale has deployed at:', contract.address);

    // check and set the withdraw limit
    let currencyUsdt = await contract.getPaymentCurrencyById(2);
    // check and set the owner
    let curOwner = await contract.owner();

    if (curOwner !== ownerAddress) {
        if (currencyUsdt.currency !== usdtAddress ) {
            console.log('   V1 MetaWorldSale currency is not set');
            await  contract.connect(deployer).addPaymentCurrency(usdtAddress);
            console.log('   V1 MetaWorldSale currency set to :', usdtAddress);
        } else {
            console.log('   V1 MetaWorldSale currency is :', usdtAddress);
        }

        console.log('   V1 MetaWorldSale current owner address is:', curOwner);
        await  contract.connect(deployer).transferOwnership(ownerAddress);
        console.log('   V1 MetaWorldSale owner address set to:', ownerAddress);
    } else {
        console.log('   V1 MetaWorldSale owner address already is:', ownerAddress);
    }
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
