require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-deploy");
require("hardhat-deploy-ethers");

task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

module.exports = {
  namedAccounts: {
    deployer: {
      default: 0,
    },
    governor: {
      default: 1,
    },
  },
  etherscan: {
    // Your API key for Scan
    // apiKey: "5JXANZPM1PDT5U3KXGRSW2QYM14VV69F6P" // Etherscan
    // apiKey: "GJYYR3HBA2DWINR24B64RAKHWH535RXFIR" // HecoInfo
    apiKey: "C8577GTIXAR7I4PX1GEWDB7M8TXARRR91Q" // Bsc

  },
  networks: {
    ropsten: {
      url: 'https://ropsten.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161',
      accounts: ['f13b65a07bd82bd2da74d3f3da0d66ba9b9feff4417d0e2d377dce57e1575f9c'] //0x6aFa4c4342De9E292fd02EeD450AeF625C488D7d
    },
    rinkeby: {
      url: 'https://rinkeby.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161',
      accounts: ['f13b65a07bd82bd2da74d3f3da0d66ba9b9feff4417d0e2d377dce57e1575f9c'] //0x6aFa4c4342De9E292fd02EeD450AeF625C488D7d
    },
    mainnet: {
      url: 'https://ropsten.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161',
      accounts: ['f13b65a07bd82bd2da74d3f3da0d66ba9b9feff4417d0e2d377dce57e1575f9c'] //0x6aFa4c4342De9E292fd02EeD450AeF625C488D7d
    },
    heco_testnet: {
      chainId: 256,
      url: 'https://http-testnet.hecochain.com',
      accounts: ['f13b65a07bd82bd2da74d3f3da0d66ba9b9feff4417d0e2d377dce57e1575f9c'], //0x6aFa4c4342De9E292fd02EeD450AeF625C488D7d
    },
    heco: {
      chainId: 128,
      url: 'https://http-mainnet.hecochain.com',
      accounts: ['f13b65a07bd82bd2da74d3f3da0d66ba9b9feff4417d0e2d377dce57e1575f9c'], //0x6aFa4c4342De9E292fd02EeD450AeF625C488D7d
    },
    bsc_testnet: {
      chainId: 97,
      url: 'https://data-seed-prebsc-1-s3.binance.org:8545/',
      gasPrice: 10000000000,
      accounts: ['f13b65a07bd82bd2da74d3f3da0d66ba9b9feff4417d0e2d377dce57e1575f9c']
    },
    bsc: {
      chainId: 56,
      url: 'https://bsc-dataseed1.defibit.io/',
      accounts: ['f13b65a07bd82bd2da74d3f3da0d66ba9b9feff4417d0e2d377dce57e1575f9c']
    },
  },

  solidity: {
    compilers: [
      {
        version: "0.8.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1337
          },
          "outputSelection": {
            "*": {
              "*": [
                "evm.bytecode",
                "evm.deployedBytecode",
                "abi"
              ]
            }
          },
          "metadata": {
            "useLiteralContent": true
          },
          "libraries": {}
        }
      },
      {
        version: "0.7.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          },
          "outputSelection": {
            "*": {
              "*": [
                "evm.bytecode",
                "evm.deployedBytecode",
                "abi"
              ]
            }
          },
          "metadata": {
            "useLiteralContent": true
          },
          "libraries": {}
        }
      },
      {
        version: "0.6.12",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.6.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.5.16",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.5.5",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      }
    ],
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  mocha: {
    timeout: 1200000
  }
};
