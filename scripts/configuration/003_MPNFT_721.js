async function sleep(ms) {
    return new Promise((resolve) => {
        setTimeout(() => {
            resolve('');
        }, ms)
    });
}

async function main() {
    const { get } = deployments;
    const [ deployer ] = await ethers.getSigners();

    const operatorAddr = "0x644BbfEF5E0305fBDcA426eD6ef712b9303eaBAd"

    console.log('deployer is ', deployer.address)

    // deployed check
    const MP = await get('MP');
    let mpToken = await ethers.getContractAt(MP.abi, MP.address, deployer);
    await mpToken.deployed();
    console.log('1. V2 MP has deployed at:', mpToken.address);

    // check and set the operator minter(the operator proxy contract address)
    let curOperator = await mpToken.operator();
    if (curOperator != operatorAddr) {
        console.log('   V1 MP current operator address is:', curOperator);
        await  mpToken.setOperator(operatorAddr);
        console.log('   V1 MP operator address set to:', operatorAddr);
    } else {
        console.log('   V1 MP operator address already is:', operatorAddr);
    }


}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
