async function sleep(ms) {
    return new Promise((resolve) => {
        setTimeout(() => {
            resolve('');
        }, ms)
    });
}

const operatorAddr = "0xf641842C9e753177CBAcFf8DfB2cC90F25324873"
const metaWorldAddress = "0xB71c4a9c6Bb7ae2379A20437596bec24A35931D2"

async function main() {
    const { get } = deployments;
    const [ deployer ] = await ethers.getSigners();

    console.log('deployer is ', deployer.address)

    // deployed check
    const MetaWorld = await ethers.getContractFactory("contracts/MetaWorld.sol:MetaWorld");
    const metaWorldToken = new ethers.Contract(metaWorldAddress, MetaWorld.interface, ethers.provider);

    await metaWorldToken.deployed();
    console.log('1. V1 meta world has deployed at:', metaWorldToken.address);

    // check and set the operator minter(the operator proxy contract address)
    let curOperator = await metaWorldToken.operator();
    if (curOperator != operatorAddr) {
        console.log('   V1 meta world current operator address is:', curOperator);
        await  metaWorldToken.connect(deployer).setOperator(operatorAddr);
        console.log('   V1 meta world operator address set to:', operatorAddr);
    } else {
        console.log('   V1 meta world operator address already is:', operatorAddr);
    }


}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
