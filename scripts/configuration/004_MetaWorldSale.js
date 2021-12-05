
async function sleep(ms) {
    return new Promise((resolve) => {
        setTimeout(() => {
            resolve('');
        }, ms)
    });
}
// heco testnet
// const metaWorldAddress = "0xf641842C9e753177CBAcFf8DfB2cC90F25324873"
// let usdt = "0xE65673Ce68C0caaBEF36e5301c7A7654E630a2C6";

// bsc testnet
const metaWorldAddress = "0x49f4Bab1F968a959FC201c047f632F7ADbedc9E9"
let usdt = "0xE65673Ce68C0caaBEF36e5301c7A7654E630a2C6";


async function main() {
    const { get } = deployments;
    const [ deployer ] = await ethers.getSigners();


    console.log('deployer is ', deployer.address)

    // deployed check
    const MetaWorldSale = await ethers.getContractFactory("contracts/MetaWorldSale.sol:MetaWorldSale");
    const contract = new ethers.Contract(metaWorldAddress, MetaWorldSeal.interface, ethers.provider);

    console.log('1. V1 MetaWorldSale has deployed at:', contract.address);

    // check and set the withdraw limit
    let currencyUsdt = await contract.getPaymentCurrencyById(2);
    if (currencyUsdt.currency != usdt ) {
        console.log('   V1 MetaWorldSale currency is not set');
        await  operatorProxy.connect(deployer).addPaymentCurrency(usdt);
        console.log('   V1 MetaWorldSale currency set to :', usdt);
    } else {
        console.log('   V1 MetaWorldSale currency is :', usdt);
    }


}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
