// We import Chai to use its asserting functions here.
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { keccak256} = require('ethereumjs-util')
const {BigNumber} = require("ethers");

describe("MPNFT_721 V1", function () {

  let MP;
  let hardhatMp;
  let owner;    // 合约部署方
  let operator; // 合约后台操作方
  let minter;
  let addrs;


  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    const params = [
    ];

    MP = await ethers.getContractFactory("MP");
    [owner, operator, minter, ...addrs] = await ethers.getSigners();

    hardhatMp = await MP.deploy(params);

  });

  // You can nest describe calls to create subsections.
  describe("Deployment", function () {

    it("Should set the right owner", async function () {
      expect(await hardhatMp.owner()).to.equal(owner.address);
    });
  });


  describe("MintBurn", function () {
    it("Should mint and burn is ok", async function () {
      // mint1
      let id = [1,2];

      // set operator
      await  hardhatMp.connect(owner).setOperator(operator.address);
      let contractOperator = await hardhatMp.operator();
      expect(contractOperator).to.equal(operator.address);

      // operator mint nft id 1 and id 2 to minter
      await  hardhatMp.connect(operator).operatorMint(minter.address, id);
      let balance = await hardhatMp.balanceOf(minter.address);
      expect(balance).to.equal(2);

      // aprove the nft from minter to operator
      await hardhatMp.connect(minter).approve(operator.address, id[0])
      let isSelfOwner =  operator.address == minter.address
      let isAproved =  await hardhatMp.getApproved(id[0]) == operator.address
      let isApprovedAll = await hardhatMp.isApprovedForAll(minter.address, operator.address)
      isAproved = isAproved | isSelfOwner | isApprovedAll
      expect(isAproved).to.equal(1);

      // burn by operator
      await hardhatMp.connect(operator).burn(id[0])

      // balance is must 1
      balance = await hardhatMp.balanceOf(minter.address);
      expect(balance).to.equal(1);

      console.log("\t Mint and burn test done");
    });

  });

});
