async function sleep(ms) {
    return new Promise((resolve) => {
        setTimeout(() => {
            resolve('');
        }, ms)
    });
}

const operatorAddress = "0x70997970c51812dc3a010c7d01b50e0d17dc79c8";
const operatorPrivite = "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d";

// heco testnet
//const metaWorldAddress = "0x431cF2d9cdb78C9324Ae72d3567a951577658e16"

// bsc testnet
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
    if (curOperator != operatorAddress) {
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
