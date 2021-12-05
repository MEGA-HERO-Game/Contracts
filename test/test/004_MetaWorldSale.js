// We import Chai to use its asserting functions here.
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { keccak256} = require('ethereumjs-util')
const {BigNumber} = require("ethers");

async function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve('');
    }, ms)
  });
}

function mineBlock() {
  return network.provider.request({ method: 'evm_mine', params: []});
}
describe("MetaWorldSale V1", function () {

  let owner;
  let operator;
  let minter;
  let buyer;
  let platformRecipienter;
  let hardhatMetaWorld;
  let oldMPNFT;
  let usdt;
  let ibox;
  let invitationSigner;
  let withdrawSigner;
  let hardhatMetaWorldSale;
  let hardhatUSDT;
  let hardhatWBTC;

  let mintAmount = "100";

  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    [owner, operator, minter, buyer, platformRecipienter, ...addrs] = await ethers.getSigners();

    invitationSigner = ibox = withdrawSigner = oldMPNFT = usdt = operator;

    // ---------------------------------------------------------------
    //  deploy the MtetaWorld nft;
    let MetaWorld = await ethers.getContractFactory("MetaWorld");
    hardhatMetaWorld = await MetaWorld.deploy(withdrawSigner.address);
    await  hardhatMetaWorld.connect(owner).setOperator(operator.address);

    // ---------------------------------------------------------------
    // Mint a metaworld token(mint nft)
    //  withdraw
    let _mpIds = [1,2,3,4,5];
    await  hardhatMetaWorld.connect(operator).operatorMint(minter.address, _mpIds);
    let balance = await hardhatMetaWorld.balanceOf(minter.address);
    expect(balance).to.equal(5);

    // ---------------------------------------------------------------
    //  deploy the USDT;
    let USDT = await ethers.getContractFactory("TokenERC20");
    hardhatUSDT = await USDT.deploy("USDT", "USDT");
    await hardhatUSDT.connect(owner).mint(buyer.address,  ethers.utils.parseUnits(mintAmount));
    balance = await hardhatUSDT.balanceOf(buyer.address);
    expect(balance).to.equal( ethers.utils.parseUnits(mintAmount).toBigInt());

    // ---------------------------------------------------------------
    //  deploy the WBTC;
    let WBTC = await ethers.getContractFactory("TokenERC20");
    hardhatWBTC = await USDT.deploy("WBTC", "WBTC");
    await hardhatWBTC.connect(owner).mint(buyer.address,  ethers.utils.parseUnits(mintAmount));
    balance = await hardhatWBTC.balanceOf(buyer.address);
    expect(balance).to.equal( ethers.utils.parseUnits(mintAmount).toBigInt());


    //  deploy the MtetaWorld Sale;
    let MetaWorldSale = await ethers.getContractFactory("MetaWorldSale");
    hardhatMetaWorldSale = await MetaWorldSale.deploy(hardhatMetaWorld.address, platformRecipienter.address ,200);


    // set support currency
    await hardhatMetaWorldSale.addPaymentCurrency(hardhatUSDT.address);
    await hardhatMetaWorldSale.addPaymentCurrency(hardhatWBTC.address);

    let supportCurrencies = await hardhatMetaWorldSale.getPaymentCurrencies();
    console.log("support currencies is", JSON.stringify(supportCurrencies));

  });

  describe("platform currency sales", function () {
    it("Should currencies configuration is ok", async function () {
      // disable usdt
      await hardhatMetaWorldSale.disablePaymentCurrency(hardhatUSDT.address);
      let supportCurrencyUSDT = await hardhatMetaWorldSale.getPaymentCurrencyById(2);
      expect(supportCurrencyUSDT.validity).to.equal(false);

      // enable usdt
      await hardhatMetaWorldSale.enablePaymentCurrency(hardhatUSDT.address);
      supportCurrencyUSDT = await hardhatMetaWorldSale.getPaymentCurrencyById(2);
      expect(supportCurrencyUSDT.validity).to.equal(true);

      // disable usdt
      await hardhatMetaWorldSale.disablePaymentCurrency(hardhatUSDT.address);
      supportCurrencyUSDT = await hardhatMetaWorldSale.getPaymentCurrencyById(2);
      expect(supportCurrencyUSDT.validity).to.equal(false);
    });

    it("Should currencies read is ok", async function () {
      let supportCurrencyUSDT = await hardhatMetaWorldSale.getPaymentCurrencyById(2);
      console.log("support currency USDT  is", JSON.stringify(supportCurrencyUSDT));

      let supportCurrencyWBTC = await hardhatMetaWorldSale.getPaymentCurrencyById(3);
      console.log("support currency WBTC  is", JSON.stringify(supportCurrencyWBTC));

      let supportCurrencyOther = await hardhatMetaWorldSale.getPaymentCurrencyById(4);
      expect(supportCurrencyOther.validity).to.equal(false);
      expect(supportCurrencyOther.id).to.equal(0);
      expect(supportCurrencyOther.currency).to.equal("0x0000000000000000000000000000000000000000");

    });

  });

  describe("Meta World sales", function () {
    it("Should use platform currency sales is ok", async function () {
      // approve tokenid 1 to hardhatMetaWorldSale and list it
      await hardhatMetaWorld.connect(minter).approve(hardhatMetaWorldSale.address, 1);

      mineBlock();
      let price = ethers.utils.parseEther('1');
      let startSaleTime =  Date.parse(new Date())/1000 + 60;
      await hardhatMetaWorldSale.connect(minter).list(1, price, 1, parseInt(startSaleTime));

      let balance = await hardhatMetaWorld.balanceOf(minter.address);
      expect(balance).to.equal(4);
      balance = await hardhatMetaWorld.balanceOf(hardhatMetaWorldSale.address);
      expect(balance).to.equal(1);

      let token1 = await hardhatMetaWorldSale.sellingNFTs(1);

      console.log("sale token id 1 info  is", JSON.stringify(token1));

      // buy the token id 1
      let pay = ethers.utils.parseEther('1.2');

      mineBlock();

      let waitTime = 20;
      for (var i = 0; i< waitTime; i++){
        await sleep(1000);
        if ( i%3 == 0) {
          console.log('  wait start sale after', waitTime - i, " s");
        }
      }
      let tx = await hardhatMetaWorldSale.connect(buyer).buy(1,
          {value: pay}
      );

      balance = await hardhatMetaWorld.balanceOf(hardhatMetaWorldSale.address);
      expect(balance).to.equal(0);

      balance = await hardhatMetaWorld.balanceOf(buyer.address);
      expect(balance).to.equal(1);

      balance = await  ethers.provider.getBalance(buyer.address);
      console.log("remain platform currency is:", ethers.utils.formatEther(balance));


      let platformRecipienterRemain="10000.2"
      balance = await  ethers.provider.getBalance(platformRecipienter.address);
      expect(ethers.utils.formatEther(balance)).to.equal(platformRecipienterRemain);

    });

    it("Should use WBTC sales is ok", async function () {

      let price = ethers.utils.parseUnits('1');

      // approve wbtc to hardhatMetaWorldSale
      await hardhatWBTC.connect(buyer).approve(hardhatMetaWorldSale.address, price);

      // approve tokenid 2 to hardhatMetaWorldSale and list it
      await hardhatMetaWorld.connect(minter).approve(hardhatMetaWorldSale.address, 2);

      mineBlock();

      let startSaleTime =  Date.parse(new Date())/1000 + 60;
      await hardhatMetaWorldSale.connect(minter).list(2, price, 3, startSaleTime );

      let balance = await hardhatMetaWorld.balanceOf(minter.address);
      expect(balance).to.equal(4);
      balance = await hardhatMetaWorld.balanceOf(hardhatMetaWorldSale.address);
      expect(balance).to.equal(1);

      let token2 = await hardhatMetaWorldSale.sellingNFTs(2);

      console.log("sale token id 2 info  is", JSON.stringify(token2));

      mineBlock();

      let waitTime = 20;
      for (var i = 0; i< waitTime; i++){
          await sleep(1000);
          if ( i%3 == 0) {
              console.log('  wait start sale after', waitTime - i, " s");
          }
      }

      let tx = await hardhatMetaWorldSale.connect(buyer).buy(2);

      let buyerRemainWBC = "99";
      let minterRemainWBTC="0.8";
      let platformRecipienterRemainWBTC="0.2"
      balance = await hardhatWBTC.balanceOf(buyer.address);
      expect(balance).to.equal(ethers.utils.parseUnits(buyerRemainWBC));

      balance = await hardhatWBTC.balanceOf(minter.address);
      expect(balance).to.equal(ethers.utils.parseUnits(minterRemainWBTC));

      balance = await hardhatWBTC.balanceOf(platformRecipienter.address);
      expect(balance).to.equal(ethers.utils.parseUnits(platformRecipienterRemainWBTC));

    });

  });

});
