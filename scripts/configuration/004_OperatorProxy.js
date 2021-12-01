
async function sleep(ms) {
    return new Promise((resolve) => {
        setTimeout(() => {
            resolve('');
        }, ms)
    });
}

const operatorProxyAddress = "0xf641842C9e753177CBAcFf8DfB2cC90F25324873"

async function main() {
    const { get } = deployments;
    const [ deployer ] = await ethers.getSigners();

    let mpLimit = 100;
    console.log('deployer is ', deployer.address)

    // deployed check
    const OperatorProxy = await ethers.getContractFactory("contracts/OperatorProxy.sol:Operator");
    const operatorProxy = new ethers.Contract(operatorProxyAddress, OperatorProxy.interface, ethers.provider);

    console.log('1. V1 operator proxy has deployed at:', operatorProxy.address);

    // check and set the withdraw limit
    let curMpLimit = await operatorProxy.mpLimit();
    if (curMpLimit != mpLimit ) {
        console.log('   V1 operator current MpLimit is:', curMpLimit);
        await  operatorProxy.connect(deployer).setLimit(mpLimit);
        console.log('   V1 operator MpLimit set to :', mpLimit);
    } else {
        console.log('   V1 operator MpLimit is:', curMpLimit);
    }


}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
