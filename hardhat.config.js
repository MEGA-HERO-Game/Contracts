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
    // apiKey: "QHSTPZUM8UCKX3RY6TTUI2YIAXYCIKK7I4" // Etherscan
    apiKey: "GJYYR3HBA2DWINR24B64RAKHWH535RXFIR" // HecoInfo

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
