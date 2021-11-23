
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

    let diamondLimit = 100;
    let mpLimit = 100;

    console.log('deployer is ', deployer.address)

    // deployed check
    const Operator = await get('Operator');
    let operatorProxy = await ethers.getContractAt(Operator.abi, Operator.address, deployer);
    await operatorProxy.deployed();
    console.log('1. V1 operator proxy has deployed at:', operatorProxy.address);

    // check and set the withdraw limit
    let curDiamondLimit = await operatorProxy.diamondLimit();
    let curMpLimit = await operatorProxy.mpLimit();if (curMpLimit != mpLimit || curDiamondLimit != diamondLimit) {
        console.log('   V1 operator current MpLimit is:', curMpLimit);
        console.log('   V1 operator current diamondLimit is:', curDiamondLimit);
        await  operatorProxy.setLimit(diamondLimit, mpLimit);
        console.log('   V1 operator MpLimit set to :', mpLimit);
        console.log('   V1 operator diamondLimit set to:', diamondLimit);
    } else {
        console.log('   V1 operator diamondLimit is:', curDiamondLimit, 'MpLimit is:', curMpLimit);
    }


}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
